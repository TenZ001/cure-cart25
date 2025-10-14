import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ApiService {
  // In-memory cache for pharmacies to enable quick lookup by id
  static Map<String, Map<String, dynamic>> _pharmacyCacheById = <String, Map<String, dynamic>>{};
  static DateTime? _pharmacyCacheAt;

  /// Register a new user
  Future<bool> registerUser(
    String name,
    String email,
    String password,
    String role,
  ) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/auth/register");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "role": role,
          // Optional extended fields for delivery partner
          // You can pass nulls for non-delivery roles
          "phone": _pendingRegisterExtras["phone"],
          "address": _pendingRegisterExtras["address"],
          "dob": _pendingRegisterExtras["dob"],
          "vehicleType": _pendingRegisterExtras["vehicleType"],
          "vehicleNumber": _pendingRegisterExtras["vehicleNumber"],
          "nic": _pendingRegisterExtras["nic"],
          "emergencyContactName": _pendingRegisterExtras["emergencyContactName"],
          "emergencyContactPhone": _pendingRegisterExtras["emergencyContactPhone"],
        }),
      );

      if (response.statusCode == 201) {
        return true;
      }
      throw HttpException(response.body, uri: url);
    } catch (e) {
      rethrow;
    }
  }

  // Temporary holder for additional register fields prior to submit
  static Map<String, dynamic> _pendingRegisterExtras = {};

  void setPendingRegisterExtras(Map<String, dynamic> extras) {
    _pendingRegisterExtras = extras;
  }

  /// Login user
  Future<bool> loginUser(String email, String password, String role) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/auth/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password, "role": role}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", data["token"]);
        await prefs.setString("user", jsonEncode(data["user"]));

        // Also login to Web API to obtain a valid web token for /api/* endpoints
        // This is optional - if web server is not available, continue with backend login
        try {
          final webLoginUrl = Uri.parse("${ApiConfig.webBaseUrl}/auth/login");
          final webRes = await http.post(
            webLoginUrl,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "password": password}),
          );
          if (webRes.statusCode == 200) {
            final webData = jsonDecode(webRes.body);
            final String? webToken = webData["token"]?.toString();
            if (webToken != null && webToken.isNotEmpty) {
              await prefs.setString("web_token", webToken);
            }
            // Optionally persist web user for debugging
            if (webData["user"] != null) {
              await prefs.setString("web_user", jsonEncode(webData["user"]));
            }
            print("✅ Web login successful");
          } else {
            print("⚠️ Web login failed: ${webRes.statusCode} ${webRes.body}");
          }
        } catch (e) {
          print("⚠️ Web login error (continuing with backend login): $e");
        }

        // If delivery partner, notify admin (fire and forget)
        if (data["user"]?["role"] == "delivery") {
          try {
            final notifyUrl = Uri.parse("${ApiConfig.baseUrl}/delivery/login-notify");
            http.post(
              notifyUrl,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"userId": data["user"]["id"]}),
            );
          } catch (_) {}
        }

        return true;
      }
      throw HttpException(response.body, uri: url);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload prescription
  Future<bool> uploadPrescription({
    required String customerId,
    required File image,
    String? notes,
    String? pharmacyId,
    String? customerAddress,
    String? customerPhone,
    int? customerAge,
    String? customerGender,
    String? paymentMethod,
  }) async {
    // Try web server first: POST /api/prescriptions (multipart 'image')
    // Fallback to backend: POST /api/prescriptions/upload
    Future<bool> sendTo(Uri url) async {
      final token = await getToken();
      final request = http.MultipartRequest("POST", url);
      request.fields["customerId"] = customerId;
      if (notes != null) request.fields["notes"] = notes;
      if (pharmacyId != null && pharmacyId.isNotEmpty) {
        request.fields["pharmacyId"] = pharmacyId;
      }
      if (customerAddress != null && customerAddress.isNotEmpty) {
        request.fields["customerAddress"] = customerAddress;
      }
      if (customerPhone != null && customerPhone.isNotEmpty) {
        request.fields["customerPhone"] = customerPhone;
      }
      if (customerAge != null) {
        request.fields["customerAge"] = customerAge.toString();
      }
      if (customerGender != null && customerGender.isNotEmpty) {
        request.fields["customerGender"] = customerGender;
      }
      if (paymentMethod != null && paymentMethod.isNotEmpty) {
        request.fields["paymentMethod"] = paymentMethod;
      }
      if (token != null && token.isNotEmpty) {
        request.headers["Authorization"] = "Bearer $token";
        request.headers["Accept"] = "application/json";
      }
      request.files.add(await http.MultipartFile.fromPath("image", image.path));
      final response = await request.send();
      return response.statusCode == 200 || response.statusCode == 201;
    }

    // Attempt web server
    try {
      final webUrl = Uri.parse("${ApiConfig.webBaseUrl}/prescriptions");
      final ok = await sendTo(webUrl);
      if (ok) return true;
    } catch (_) {}

    // Fallback to backend server
    try {
      final beUrl = Uri.parse("${ApiConfig.baseUrl}/prescriptions/upload");
      final ok = await sendTo(beUrl);
      if (ok) return true;
    } catch (_) {}

    return false;
  }

  /// Get prescriptions for a user (filtered by customerId)
  Future<List<Map<String, dynamic>>> getPrescriptions(String customerId) async {
    // Prefer web server (query param), then fallback to backend variants
    final headers = <String, String>{};
    try {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
        headers["Accept"] = "application/json";
      }
    } catch (_) {}

    // Web server: /prescriptions?customerId=...
    try {
      final webUrl = Uri.parse("${ApiConfig.webBaseUrl}/prescriptions?customerId=$customerId");
      final res = await http.get(webUrl, headers: headers.isEmpty ? null : headers);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (_) {}

    // Backend: /prescriptions?customerId=...
    try {
      final urlQuery = Uri.parse("${ApiConfig.baseUrl}/prescriptions?customerId=$customerId");
      final responseQuery = await http.get(urlQuery, headers: headers.isEmpty ? null : headers);
      if (responseQuery.statusCode == 200) {
        final List data = jsonDecode(responseQuery.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (_) {}

    // Backend: /prescriptions/:customerId
    try {
      final urlPath = Uri.parse("${ApiConfig.baseUrl}/prescriptions/$customerId");
      final responsePath = await http.get(urlPath, headers: headers.isEmpty ? null : headers);
      if (responsePath.statusCode == 200) {
        final List data = jsonDecode(responsePath.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (_) {}

    return [];
  }

  /// List approved pharmacies (from web public API)
  Future<List<Map<String, dynamic>>> getApprovedPharmacies() async {
    // Helper to normalize pharmacy objects for UI expectations
    List<Map<String, dynamic>> _normalize(List input) {
      return List<Map<String, dynamic>>.from(input.map((raw) {
        final Map<String, dynamic> source = Map<String, dynamic>.from(raw as Map);
        final String? id = (source['_id'] ?? source['id'] ?? source['pharmacyId'])?.toString();
        final String? contact = (source['phone'] ?? source['contact'])?.toString();
        final dynamic image = source.containsKey('image') ? source['image'] : (source['logo'] ?? source['photo']);
        return <String, dynamic>{
          ...source,
          if (id != null) 'id': id,
          if (!source.containsKey('phone') && contact != null) 'phone': contact,
          if (!source.containsKey('image') && image != null) 'image': image,
        };
      }));
    }

    Future<List<Map<String, dynamic>>> _tryUrl(Uri url) async {
      print('🌐 API Service fetching pharmacies from: $url');
      final response = await http.get(url);
      print('📡 Pharmacies status: ${response.statusCode}');
      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is List) {
            final rows = _normalize(decoded);
            print('✅ Parsed ${rows.length} pharmacies');
            return rows;
          } else {
            print('❌ Unexpected pharmacies payload (not a list)');
          }
        } catch (e) {
          print('❌ Failed to decode pharmacies JSON: $e');
        }
      } else {
        print('❌ Pharmacies request failed: ${response.statusCode} ${response.body}');
      }
      return <Map<String, dynamic>>[];
    }

    try {
      // Use backend API for pharmacies (http://172.20.10.3:5000/api/pharmacies)
      final Uri primary = Uri.parse("${ApiConfig.baseUrl}/pharmacies");
      final primaryRows = await _tryUrl(primary);
      if (primaryRows.isNotEmpty) return primaryRows;

      // Fallback: Try alternative IP (192.168.17.176)
      final Uri altIp = Uri.parse("${ApiConfig.localNetworkBaseUrl2}/pharmacies");
      final altIpRows = await _tryUrl(altIp);
      if (altIpRows.isNotEmpty) return altIpRows;

      // Fallback: Try web server if backend fails
      final Uri webFallback = Uri.parse("${ApiConfig.webBaseUrl.replaceFirst('/api', '')}/public/pharmacies");
      final webRows = await _tryUrl(webFallback);
      if (webRows.isNotEmpty) return webRows;

      // Fallback: Try web server with alternative IP
      final Uri webAltIp = Uri.parse("${ApiConfig.localNetworkWebBaseUrl2.replaceFirst('/api', '')}/public/pharmacies");
      final webAltIpRows = await _tryUrl(webAltIp);
      if (webAltIpRows.isNotEmpty) return webAltIpRows;

      // Host swap fallback (10.0.2.2 <-> localhost) for emulator/desktop mismatch
      final String swapped = ApiConfig.baseUrl.contains('10.0.2.2')
          ? ApiConfig.baseUrl.replaceFirst('10.0.2.2', 'localhost')
          : ApiConfig.baseUrl.replaceFirst('localhost', '10.0.2.2');
      if (swapped != ApiConfig.baseUrl) {
        final Uri alt = Uri.parse("${swapped}/pharmacies");
        final altRows = await _tryUrl(alt);
        if (altRows.isNotEmpty) return altRows;
      }
    } catch (e) {
      print('❌ API Service error fetching pharmacies: $e');
    }
    return <Map<String, dynamic>>[];
  }


  /// Get a single pharmacy by id (from approved list). Caches for 15 minutes.
  Future<Map<String, dynamic>?> getPharmacyById(String pharmacyId) async {
    try {
      final bool cacheExpired = _pharmacyCacheAt == null || DateTime.now().difference(_pharmacyCacheAt!).inMinutes > 15;
      if (_pharmacyCacheById.isEmpty || cacheExpired) {
        final list = await getApprovedPharmacies();
        final map = <String, Map<String, dynamic>>{};
        for (final p in list) {
          final id = (p['_id'] ?? p['id'] ?? p['pharmacyId'])?.toString();
          if (id != null && id.isNotEmpty) {
            map[id] = Map<String, dynamic>.from(p);
          }
        }
        _pharmacyCacheById = map;
        _pharmacyCacheAt = DateTime.now();
      }
      final key = pharmacyId.toString();
      if (_pharmacyCacheById.containsKey(key)) return _pharmacyCacheById[key];
      // As a last resort, refresh once
      final list = await getApprovedPharmacies();
      for (final p in list) {
        final id = (p['_id'] ?? p['id'] ?? p['pharmacyId'])?.toString();
        if (id != null && id.isNotEmpty) {
          _pharmacyCacheById[id] = Map<String, dynamic>.from(p);
        }
      }
      return _pharmacyCacheById[key];
    } catch (e) {
      return null;
    }
  }

  // ===== Delivery APIs =====
  Future<List<Map<String, dynamic>>> getAssignedOrders(String partnerId) async {
    // Use web public endpoint which includes joined prescription details
    final webUrl = Uri.parse("${ApiConfig.webBaseUrl.replaceFirst('/api','')}/public/delivery/assigned?partnerId=$partnerId");
    try {
      print("🔍 [MOBILE] Getting assigned orders from web server: $webUrl");
      final res = await http.get(webUrl);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        print("✅ [MOBILE] Got assigned orders from web server: ${data.length}");
        print("📋 [MOBILE] Sample order data: ${data.isNotEmpty ? data[0] : 'No data'}");
        return List<Map<String, dynamic>>.from(data);
      } else {
        print("❌ [MOBILE] Web server returned status: ${res.statusCode}");
      }
    } catch (e) {
      print("❌ [MOBILE] Web server error: $e");
    }
    
    // Fallback to legacy mobile endpoint
    final url = Uri.parse("${ApiConfig.baseUrl}/delivery/assigned?partnerId=$partnerId");
    try {
      print("🔍 [MOBILE] Fallback to backend server: $url");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        print("✅ [MOBILE] Got assigned orders from backend: ${data.length}");
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print("❌ getAssignedOrders error: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/delivery/orders/$orderId");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("❌ getOrderById error: $e");
      return null;
    }
  }

  /// Web: get extra order details joined with prescription
  Future<Map<String, dynamic>?> getOrderDetailsWeb(String orderId) async {
    // Try public endpoint first (no auth required), then fallback to /api with bearer when available
    try {
      final pub = Uri.parse("${ApiConfig.webBaseUrl.replaceFirst('/api','')}/public/orders/$orderId/details");
      final r1 = await http.get(pub);
      if (r1.statusCode == 200) {
        return jsonDecode(r1.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    try {
      final url = Uri.parse("${ApiConfig.webBaseUrl}/orders/$orderId/details");
      final token = await getWebToken() ?? await getToken();
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
      final response = await http.get(url, headers: headers.isEmpty ? null : headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print("❌ getOrderDetailsWeb error: $e");
    }
    return null;
  }

  /// Web: get a customer's profile and related data by id
  Future<Map<String, dynamic>?> getCustomerByIdWeb(String customerId) async {
    try {
      final token = await getWebToken() ?? await getToken();
      final headers = <String, String>{"Accept": "application/json"};
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
      final url = Uri.parse("${ApiConfig.webBaseUrl}/customers/$customerId");
      final res = await http.get(url, headers: headers);
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        // Endpoint returns { customer, orders, prescriptions }
        if (data['customer'] is Map) {
          return Map<String, dynamic>.from(data['customer']);
        }
        return data;
      }
    } catch (e) {
      print("❌ getCustomerByIdWeb error: $e");
    }
    return null;
  }

  /// Web: delete an order permanently
  Future<bool> deleteOrderWeb(String orderId) async {
    try {
      final user = await getUser();
      final String? customerId = user != null ? user['id']?.toString() : null;
      final url = Uri.parse("${ApiConfig.webBaseUrl}/orders/$orderId${customerId != null ? '?customerId=' + Uri.encodeComponent(customerId) : ''}");
      
      print('🗑️ Deleting order from server: $url');
      print('🗑️ Order ID: $orderId, Customer ID: $customerId');
      
      final res = await http.delete(url);
      
      print('🗑️ Delete response status: ${res.statusCode}');
      print('🗑️ Delete response body: ${res.body}');
      
      if (res.statusCode == 200) {
        print('✅ Order deleted successfully from server');
        return true;
      } else {
        print('❌ Failed to delete order from server: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error deleting order from server: $e');
      return false;
    }
  }

  /// Web: update order delivery date/time
  Future<bool> updateOrderDeliveryDateWeb(String orderId, DateTime when) async {
    // Use public endpoint with partner check
    try {
      final dp = await getDeliveryProfile();
      final partnerId = dp != null ? (dp['_id']?.toString()) : null;
      if (partnerId == null || partnerId.isEmpty) return false;
      final url = Uri.parse("${ApiConfig.webBaseUrl.replaceFirst('/api','')}/public/orders/$orderId/delivery");
      final res = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"partnerId": partnerId, "deliveryDate": when.toIso8601String()}),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("❌ updateOrderDeliveryDateWeb error: $e");
      return false;
    }
  }

  Future<bool> markOrderPickedUpWeb(String orderId) async {
    try {
      print("🔍 markOrderPickedUpWeb: Starting for orderId=$orderId");
      
      final dp = await getDeliveryProfile();
      print("🔍 Delivery profile: $dp");
      
      final partnerId = dp != null ? (dp['_id']?.toString()) : null;
      if (partnerId == null || partnerId.isEmpty) {
        print("❌ No delivery partner profile found");
        print("❌ This might be because the delivery partner is not properly registered or authenticated");
        return false;
      }
      
      // First, let's check if the order exists and is assigned to this partner
      try {
        final orderDetails = await getOrderDetailsWeb(orderId);
        print("🔍 Order details: $orderDetails");
        if (orderDetails != null) {
          final order = orderDetails['order'] as Map<String, dynamic>?;
          final assignedPartnerId = order?['deliveryPartnerId']?.toString();
          print("🔍 Order assigned to partner: $assignedPartnerId");
          print("🔍 Current partner: $partnerId");
          if (assignedPartnerId != partnerId) {
            print("❌ Order not assigned to this delivery partner");
            return false;
          }
        }
      } catch (e) {
        print("⚠️ Could not verify order assignment: $e");
      }
      
      final url = Uri.parse("${ApiConfig.webBaseUrl.replaceFirst('/api','')}/public/orders/$orderId/delivery");
      print("🔍 PATCH URL: $url");
      print("🔍 Payload: partnerId=$partnerId, pickedUp=true");
      
      final res = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "partnerId": partnerId, 
          "pickedUp": true,
          "pickedUpAt": DateTime.now().toIso8601String(),
          "status": "out_for_delivery"
        }),
      );
      
      print("🔍 Response status: ${res.statusCode}");
      print("🔍 Response body: ${res.body}");
      
      if (res.statusCode == 200) {
        print("✅ markOrderPickedUpWeb: Success");
        return true;
      } else {
        print("❌ markOrderPickedUpWeb: Failed with status ${res.statusCode}");
        print("❌ Response body: ${res.body}");
        // Try fallback to public API
        return await _markOrderPickedUpBackend(orderId);
      }
    } catch (e) {
      print("❌ markOrderPickedUpWeb error: $e");
      // Try fallback to backend API
      return await _markOrderPickedUpBackend(orderId);
    }
  }

  Future<bool> _markOrderPickedUpBackend(String orderId) async {
    try {
      print("🔍 Trying public API fallback for markOrderPickedUp");
      // Use public endpoint which doesn't require authentication
      final dp = await getDeliveryProfile();
      final partnerId = dp != null ? (dp['_id']?.toString()) : null;
      if (partnerId == null || partnerId.isEmpty) {
        print("❌ No delivery partner profile for fallback");
        print("🔍 Trying without partner ID validation...");
        // Try without partner ID validation as a last resort
        return await _markOrderPickedUpWithoutValidation(orderId);
      }
      
      final url = Uri.parse("${ApiConfig.webBaseUrl.replaceFirst('/api','')}/public/orders/$orderId/delivery");
      print("🔍 Public API fallback URL: $url");
      
      final res = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "partnerId": partnerId,
          "pickedUp": true,
          "pickedUpAt": DateTime.now().toIso8601String(),
          "status": "out_for_delivery"
        }),
      );
      print("🔍 Public API fallback response status: ${res.statusCode}");
      print("🔍 Public API fallback response body: ${res.body}");
      return res.statusCode == 200;
    } catch (e) {
      print("❌ Public API fallback error: $e");
      // Try without validation as last resort
      return await _markOrderPickedUpWithoutValidation(orderId);
    }
  }

  Future<bool> _markOrderPickedUpWithoutValidation(String orderId) async {
    try {
      print("🔍 Trying direct status update without validation");
      // Try to update status directly using the backend API
      final url = Uri.parse("${ApiConfig.baseUrl}/delivery/orders/$orderId/status");
      print("🔍 Direct status update URL: $url");
      
      final res = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": "out_for_delivery"}),
      );
      print("🔍 Direct status update response status: ${res.statusCode}");
      print("🔍 Direct status update response body: ${res.body}");
      return res.statusCode == 200;
    } catch (e) {
      print("❌ Direct status update error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> getOrderContact(String orderId) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/delivery/orders/$orderId/contact");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("❌ getOrderContact error: $e");
      return null;
    }
  }

  Future<bool> updateDeliveryStatus(String orderId, String status) async {
    // Try web API first, then fallback to backend
    try {
      print("🔍 updateDeliveryStatus: Starting for orderId=$orderId, status=$status");
      final dp = await getDeliveryProfile();
      print("🔍 updateDeliveryStatus: Delivery profile: $dp");
      final partnerId = dp != null ? (dp['_id']?.toString()) : null;
      if (partnerId == null || partnerId.isEmpty) {
        print("❌ No delivery partner profile found");
        return false;
      }
      
      final webUrl = Uri.parse("${ApiConfig.webBaseUrl.replaceFirst('/api','')}/public/orders/$orderId/delivery");
      print("🔍 updateDeliveryStatus: Web URL: $webUrl");
      print("🔍 updateDeliveryStatus: Payload: partnerId=$partnerId, status=$status");
      
      final res = await http.patch(
        webUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "partnerId": partnerId,
          "status": status,
          "delivered": status == 'delivered',
          "deliveredAt": status == 'delivered' ? DateTime.now().toIso8601String() : null
        }),
      );
      
      print("🔍 updateDeliveryStatus: Response status: ${res.statusCode}");
      print("🔍 updateDeliveryStatus: Response body: ${res.body}");
      
      if (res.statusCode == 200) {
        print("✅ Web API delivery status update successful");
        return true;
      } else {
        print("❌ Web API failed with status: ${res.statusCode}, body: ${res.body}");
      }
    } catch (e) {
      print("❌ Web API updateDeliveryStatus error: $e");
    }
    
    // Fallback to backend API
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/delivery/orders/$orderId/status");
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": status}),
      );
      if (response.statusCode == 200) {
        print("✅ Backend API delivery status update successful");
        return true;
      } else {
        print("❌ Backend API failed with status: ${response.statusCode}, body: ${response.body}");
      }
    } catch (e) {
      print("❌ Backend updateDeliveryStatus error: $e");
    }
    
    return false;
  }

  Future<bool> updateDeliveryLocation(String orderId, double lat, double lng) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/delivery/orders/$orderId/location");
    try {
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"lat": lat, "lng": lng}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("❌ updateDeliveryLocation error: $e");
      return false;
    }
  }

  /// Update user's current location
  Future<bool> updateUserLocation(double lat, double lng) async {
    try {
      final user = await getUser();
      if (user == null) {
        print("❌ No user found for location update");
        return false;
      }

      final userId = user['id']?.toString();
      if (userId == null || userId.isEmpty) {
        print("❌ No user ID found for location update");
        return false;
      }

      // Try web API first
      try {
        final webUrl = Uri.parse("${ApiConfig.webBaseUrl}/users/$userId/location");
        final token = await getWebToken() ?? await getToken();
        final headers = <String, String>{
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        };

        final response = await http.patch(
          webUrl,
          headers: headers,
          body: jsonEncode({"lat": lat, "lng": lng}),
        );

        if (response.statusCode == 200) {
          print("✅ User location updated via web API");
          return true;
        } else {
          print("❌ Web API user location update failed: ${response.statusCode} - ${response.body}");
        }
      } catch (e) {
        print("❌ Web API user location update error: $e");
      }

      // Fallback to backend API
      try {
        final url = Uri.parse("${ApiConfig.baseUrl}/users/$userId/location");
        final token = await getToken();
        final headers = <String, String>{
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        };

        final response = await http.patch(
          url,
          headers: headers,
          body: jsonEncode({"lat": lat, "lng": lng}),
        );

        if (response.statusCode == 200) {
          print("✅ User location updated via backend API");
          return true;
        } else {
          print("❌ Backend API user location update failed: ${response.statusCode} - ${response.body}");
        }
      } catch (e) {
        print("❌ Backend API user location update error: $e");
      }

      return false;
    } catch (e) {
      print("❌ updateUserLocation error: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getDeliveryHistory(String partnerId) async {
    print("🔍 getDeliveryHistory: Starting for partnerId: $partnerId");
    
    // Try web API first for consistency with updateDeliveryStatus
    try {
      final webUrl = Uri.parse("${ApiConfig.webBaseUrl.replaceFirst('/api','')}/public/delivery/history?partnerId=$partnerId");
      print("🔍 getDeliveryHistory: Web URL: $webUrl");
      
      final response = await http.get(webUrl);
      print("🔍 getDeliveryHistory: Response status: ${response.statusCode}");
      print("🔍 getDeliveryHistory: Response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        print("✅ Web API delivery history successful: ${data.length} deliveries");
        print("📦 Delivery history data: $data");
        return List<Map<String, dynamic>>.from(data);
      } else {
        print("❌ Web API delivery history failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Web API getDeliveryHistory error: $e");
    }
    
    // Fallback to backend API
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/delivery/orders/history?partnerId=$partnerId");
      print("🔍 getDeliveryHistory: Backend URL: $url");
      
      final response = await http.get(url);
      print("🔍 getDeliveryHistory: Backend response status: ${response.statusCode}");
      print("🔍 getDeliveryHistory: Backend response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        print("✅ Backend API delivery history successful: ${data.length} deliveries");
        print("📦 Backend delivery history data: $data");
        return List<Map<String, dynamic>>.from(data);
      } else {
        print("❌ Backend API delivery history failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Backend getDeliveryHistory error: $e");
    }
    
    return [];
  }

  /// Submit delivery partner signup request
  Future<bool> submitDeliverySignup({
    String? name,
    required String phone,
    required String nic,
    required String licenseNumber,
    required List<String> vehicles,
  }) async {
    final url = Uri.parse("${ApiConfig.webBaseUrl}/delivery-partners");
    try {
      final token = await getToken();
      final headers = <String, String>{"Content-Type": "application/json"};
      if (token != null && token.isNotEmpty) headers["Authorization"] = "Bearer $token";
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          if (name != null && name.isNotEmpty) "name": name,
          "phone": phone,
          "nic": nic,
          "licenseNumber": licenseNumber,
          "vehicles": vehicles,
        }),
      );
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getDeliveryProfile() async {
    try {
      final url = Uri.parse("${ApiConfig.webBaseUrl}/delivery-partners/me");
      print("🔍 getDeliveryProfile: URL = $url");
      
      final token = await getWebToken() ?? await getToken();
      print("🔍 getDeliveryProfile: Token = ${token != null ? 'Present' : 'Missing'}");
      
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) headers["Authorization"] = "Bearer $token";
      
      print("🔍 getDeliveryProfile: Headers = $headers");
      
      final res = await http.get(url, headers: headers.isEmpty ? null : headers);
      print("🔍 getDeliveryProfile: Response status = ${res.statusCode}");
      print("🔍 getDeliveryProfile: Response body = ${res.body}");
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("🔍 getDeliveryProfile: Parsed data = $data");
        return data as Map<String, dynamic>?;
      } else {
        print("❌ getDeliveryProfile: Failed with status ${res.statusCode}");
      }
    } catch (e) {
      print("❌ getDeliveryProfile error: $e");
    }
    return null;
  }

  Future<bool> updateDeliveryProfile(Map<String, dynamic> update) async {
    final url = Uri.parse("${ApiConfig.webBaseUrl}/delivery-partners/me");
    try {
      final token = await getWebToken() ?? await getToken();
      final headers = <String, String>{"Content-Type": "application/json"};
      if (token != null && token.isNotEmpty) headers["Authorization"] = "Bearer $token";
      final res = await http.patch(url, headers: headers, body: jsonEncode(update));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Confirm delivery and update all related statuses
  Future<bool> confirmDeliveryWeb(String orderId) async {
    try {
      final dp = await getDeliveryProfile();
      final partnerId = dp != null ? (dp['_id']?.toString()) : null;
      if (partnerId == null || partnerId.isEmpty) return false;
      
      final url = Uri.parse("${ApiConfig.webBaseUrl.replaceFirst('/api','')}/public/orders/$orderId/delivery");
      final res = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "partnerId": partnerId, 
          "delivered": true,
          "deliveredAt": DateTime.now().toIso8601String()
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print("❌ confirmDeliveryWeb error: $e");
      return false;
    }
  }

  /// Get saved web token (for web API endpoints)
  Future<String?> getWebToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("web_token");
  }

  /// Get saved token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /// Get saved user info
  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString("user");
    return userString != null ? jsonDecode(userString) : null;
  }


  /// Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("user");
  }

  /// 🔹 Search medicines
  Future<List<Map<String, dynamic>>> searchMedicines(String query) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/medicines/search?query=$query");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print("❌ Search failed: ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Medicine search error: $e");
      return [];
    }
  }

  /// 🔹 Get customer orders
  Future<List<Map<String, dynamic>>> getCustomerOrders(String customerId) async {
    try {
      final token = await getToken();
      final webToken = await getWebToken();
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
        headers["Accept"] = "application/json";
      }
      final webHeaders = <String, String>{};
      if (webToken != null && webToken.isNotEmpty) {
        webHeaders["Authorization"] = "Bearer $webToken";
        webHeaders["Accept"] = "application/json";
      }

      // Try web API first (with fallback host attempt)
      Future<List<Map<String, dynamic>>> tryWeb(Uri url) async {
        print("🌐 Loading customer orders from web API: $url");
        final response = await http.get(url, headers: webHeaders.isEmpty ? null : webHeaders);
        print("🌐 Customer orders response status: ${response.statusCode}");
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          print("✅ Loaded ${data.length} customer orders from web API");
          // Normalize statuses here to keep UI consistent
          return List<Map<String, dynamic>>.from(
            data.map((o) {
              final m = Map<String, dynamic>.from(o as Map);
              final s = (m['status'] ?? m['orderStatus'] ?? m['state'] ?? '').toString().toLowerCase();
              if (s == 'confirmed' || s == 'accepted' || s == 'ordered' || s.contains('confirm')) {
                m['status'] = 'processing';
              } else if (s == 'out_for_delivery' || s == 'out-for-delivery' || s == 'out for delivery' || s == 'assigned') {
                m['status'] = 'dispatched';
              } else if (s == 'completed') {
                m['status'] = 'delivered';
              }
              return m;
            })
          );
        }
        throw HttpException('Web orders failed: ${response.statusCode}', uri: url);
      }

      try {
        // Primary configured base URL
        final primary = Uri.parse("${ApiConfig.webBaseUrl}/orders/customer/$customerId");
        return await tryWeb(primary);
      } catch (e) {
        print("❌ Web API customer orders primary error: $e");
        // For Android emulator vs desktop mismatch, attempt host swap if applicable
        try {
          final alt = Uri.parse("${ApiConfig.webBaseUrl.replaceFirst('http://10.0.2.2', 'http://localhost')}/orders/customer/$customerId");
          if (alt.toString() != "${ApiConfig.webBaseUrl}/orders/customer/$customerId") {
            return await tryWeb(alt);
          }
        } catch (_) {}
      }

      // Fallback to backend API
      try {
        final url = Uri.parse("${ApiConfig.baseUrl}/orders/customer/$customerId");
        final response = await http.get(url, headers: headers.isEmpty ? null : headers);
        
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          print("✅ Loaded ${data.length} customer orders from backend API");
          // Normalize here too for consistency
          return List<Map<String, dynamic>>.from(
            data.map((o) {
              final m = Map<String, dynamic>.from(o as Map);
              final s = (m['status'] ?? m['orderStatus'] ?? m['state'] ?? '').toString().toLowerCase();
              if (s == 'confirmed' || s == 'accepted' || s == 'ordered' || s.contains('confirm')) {
                m['status'] = 'processing';
              } else if (s == 'out_for_delivery' || s == 'out-for-delivery' || s == 'out for delivery' || s == 'assigned') {
                m['status'] = 'dispatched';
              } else if (s == 'completed') {
                m['status'] = 'delivered';
              }
              return m;
            })
          );
        }
      } catch (e) {
        print("❌ Backend API customer orders error: $e");
      }

      return [];
    } catch (e) {
      print("❌ Customer orders error: $e");
      return [];
    }
  }

  /// 🔹 Process prescription order and create order
  Future<Map<String, dynamic>?> processPrescriptionOrder({
    required String prescriptionId,
    required String pharmacyId,
    required String customerAddress,
    required String customerPhone,
    required String paymentMethod,
    String? deliveryPartnerId,
  }) async {
    // Try web server first, then fallback to backend
    Future<Map<String, dynamic>?> tryWebServer() async {
      try {
        final token = await getToken();
        final url = Uri.parse("${ApiConfig.webBaseUrl}/orders/process-prescription");
        
        final headers = <String, String>{
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        };
        
        final body = {
          "prescriptionId": prescriptionId,
          "pharmacyId": pharmacyId,
          "customerAddress": customerAddress,
          "customerPhone": customerPhone,
          "paymentMethod": paymentMethod,
          if (deliveryPartnerId != null) "deliveryPartnerId": deliveryPartnerId,
        };
        
        final response = await http.post(url, headers: headers, body: jsonEncode(body));
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body);
        } else {
          print("❌ Web server process prescription order error: ${response.statusCode} - ${response.body}");
          return null;
        }
      } catch (e) {
        print("❌ Web server process prescription order error: $e");
        return null;
      }
    }

    // Try backend API as fallback
    Future<Map<String, dynamic>?> tryBackend() async {
      try {
        final token = await getToken();
        final url = Uri.parse("${ApiConfig.baseUrl}/orders/process-prescription");
        
        final headers = <String, String>{
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
        };
        
        final body = {
          "prescriptionId": prescriptionId,
          "pharmacyId": pharmacyId,
          "customerAddress": customerAddress,
          "customerPhone": customerPhone,
          "paymentMethod": paymentMethod,
          if (deliveryPartnerId != null) "deliveryPartnerId": deliveryPartnerId,
        };
        
        final response = await http.post(url, headers: headers, body: jsonEncode(body));
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body);
        } else {
          print("❌ Backend process prescription order error: ${response.statusCode} - ${response.body}");
          return null;
        }
      } catch (e) {
        print("❌ Backend process prescription order error: $e");
        return null;
      }
    }

    // Try web server first
    final webResult = await tryWebServer();
    if (webResult != null) return webResult;

    // Fallback to backend
    return await tryBackend();
  }

  /// 🔹 Get available delivery partners
  Future<List<Map<String, dynamic>>> getDeliveryPartners() async {
    try {
      final token = await getToken();
      final url = Uri.parse("${ApiConfig.webBaseUrl}/delivery-partners/available");
      
      final headers = <String, String>{
        "Content-Type": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      };
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print("❌ Get delivery partners error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Get delivery partners error: $e");
      return [];
    }
  }

  /// 🔹 Create order from checkout
  Future<Map<String, dynamic>?> createOrder({
    required List<Map<String, dynamic>> items,
    required String pharmacyId,
    required String address,
    required String paymentMethod,
    required int total,
    String? pharmacyName,
    String? pharmacyAddress,
  }) async {
    try {
      final token = await getToken();
      final user = await getUser();
      
      if (token == null || user == null) {
        print("❌ No token or user found");
        return null;
      }

      // Try web API first (preferred method)
      try {
        final webUrl = Uri.parse("${ApiConfig.webBaseUrl}/orders");
        print("🌐 Creating order via web API: $webUrl");
        print("🌐 Order details: customerId=${user["id"]}, pharmacyId=$pharmacyId, total=$total");
        print("🌐 Items: ${items.map((item) => "${item["name"]} x${item["qty"]} @Rs.${item["price"]}").join(", ")}");
        
        final orderPayload = {
          "customerId": user["id"],
          "items": items.map((item) => {
            "name": item["name"],
            "quantity": item["qty"],
            "price": item["price"],
          }).toList(),
          "total": total,
          "pharmacyId": pharmacyId,
          "address": address,
          "paymentMethod": paymentMethod,
          "status": "pending",
          if (pharmacyName != null && pharmacyName.isNotEmpty) "pharmacy": pharmacyName,
          if (pharmacyAddress != null && pharmacyAddress.isNotEmpty) "pharmacyAddress": pharmacyAddress,
        };
        
        print("🌐 Web API payload: ${jsonEncode(orderPayload)}");
        
        // Prefer web token for web API
        final String? webToken = await getWebToken();
        final response = await http.post(
          webUrl,
          headers: {
            "Content-Type": "application/json",
            if ((webToken ?? token).isNotEmpty) "Authorization": "Bearer ${webToken ?? token}",
          },
          body: jsonEncode(orderPayload),
        );

        print("🌐 Web API response status: ${response.statusCode}");
        print("🌐 Web API response body: ${response.body}");

        if (response.statusCode == 201) {
          final decoded = jsonDecode(response.body);
          // Some APIs wrap the created order as { order: {...} }
          final Map<String, dynamic> data = decoded is Map<String, dynamic>
              ? (decoded.containsKey('order') && decoded['order'] is Map<String, dynamic>
                  ? Map<String, dynamic>.from(decoded['order'] as Map)
                  : Map<String, dynamic>.from(decoded))
              : <String, dynamic>{};
          print("✅ Order created successfully via web API");
          print("✅ Order ID: ${data["_id"] ?? data["id"] ?? data["orderId"]}");
          print("✅ Order will be visible to pharmacist in web interface");
          return data;
        } else {
          print("❌ Web API failed with status ${response.statusCode}: ${response.body}");
          // Don't fall back to backend API - force web API usage
          throw Exception("Web API failed: ${response.statusCode} - ${response.body}");
        }
      } catch (e) {
        print("❌ Web API order creation failed: $e");
        // Don't fall back to backend API - force web API usage
        rethrow;
      }

      // No fallback - web API must work
      return null;
    } catch (e) {
      print("❌ Order creation error: $e");
      return null;
    }
  }

  /// 🔹 Get pharmacy orders (for pharmacist dashboard)
  Future<List<Map<String, dynamic>>> getPharmacyOrders() async {
    try {
      final token = await getToken();
      final url = Uri.parse("${ApiConfig.webBaseUrl}/admin/orders");
      
      final headers = <String, String>{
        "Content-Type": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      };
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print("❌ Get pharmacy orders error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Get pharmacy orders error: $e");
      return [];
    }
  }

  /// 🔹 Assign delivery partner to order
  Future<bool> assignDeliveryPartner(String orderId, String deliveryPartnerId) async {
    try {
      final token = await getToken();
      final url = Uri.parse("${ApiConfig.webBaseUrl}/orders/$orderId/assign-delivery");
      
      final headers = <String, String>{
        "Content-Type": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      };
      
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({
          "deliveryPartnerId": deliveryPartnerId,
        }),
      );
      
      if (response.statusCode == 200) {
        print("✅ Delivery partner assigned successfully");
        return true;
      } else {
        print("❌ Assign delivery partner error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Assign delivery partner error: $e");
      return false;
    }
  }

  /// 🔹 Confirm order
  Future<bool> confirmOrder(String orderId) async {
    try {
      final token = await getToken();
      final url = Uri.parse("${ApiConfig.webBaseUrl}/orders/$orderId/confirm");
      
      final headers = <String, String>{
        "Content-Type": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      };
      
      final response = await http.put(url, headers: headers);
      
      if (response.statusCode == 200) {
        print("✅ Order confirmed successfully");
        return true;
      } else {
        print("❌ Confirm order error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Confirm order error: $e");
      return false;
    }
  }

  /// 🔹 Submit pharmacy feedback
  Future<bool> submitPharmacyFeedback({
    required String pharmacyId,
    required int rating,
    String? comment,
  }) async {
    try {
      final user = await getUser();
      if (user == null) {
        print("❌ No user found for feedback submission");
        return false;
      }

      // Use public endpoint (no authentication required)
      final url = Uri.parse("${ApiConfig.webBaseUrl.replaceFirst('/api', '')}/public/pharmacy-feedback");
      
      final headers = <String, String>{
        "Content-Type": "application/json",
      };
      
      final body = {
        "pharmacyId": pharmacyId,
        "customerId": user["id"],
        "rating": rating,
        if (comment != null && comment.isNotEmpty) "comment": comment,
      };
      
      print("🔍 Submitting pharmacy feedback: $body");
      print("🔍 User data: $user");
      print("🔍 Customer ID: ${user["id"]}");
      print("🔍 Using public endpoint (no authentication required)");
      print("🔍 Headers: $headers");
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      print("🔍 Feedback response status: ${response.statusCode}");
      print("🔍 Feedback response body: ${response.body}");
      
      if (response.statusCode == 201) {
        print("✅ Pharmacy feedback submitted successfully");
        return true;
      } else {
        print("❌ Submit feedback error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Submit feedback error: $e");
      return false;
    }
  }
}
