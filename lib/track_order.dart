import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'api_service.dart';

class TrackOrderPage extends StatefulWidget {
  final String orderId;
  const TrackOrderPage({super.key, required this.orderId});

  @override
  State<TrackOrderPage> createState() => _TrackOrderPageState();
}

class _TrackOrderPageState extends State<TrackOrderPage> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? order;
  bool loading = true;
  Timer? _locationTimer;
  Position? _currentPosition;
  double? customerLat;
  double? customerLng;
  double? deliveryLat;
  double? deliveryLng;
  String? deliveryPartnerName;
  String? deliveryPartnerPhone;
  String? orderStatus;
  String? estimatedDelivery;
  String? deliveryAddress;
  String? pharmacyAddress;
  String? paymentMethod;
  String? customerPhone;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderData() async {
    try {
      final data = await apiService.getOrderById(widget.orderId);
      Map<String, dynamic>? webDetails;
      try {
        webDetails = await apiService.getOrderDetailsWeb(widget.orderId);
      } catch (_) {}

      setState(() {
        order = data;
        customerLat = (data?["customerLat"])?.toDouble();
        customerLng = (data?["customerLng"])?.toDouble();
        deliveryLat = (data?["deliveryLat"])?.toDouble();
        deliveryLng = (data?["deliveryLng"])?.toDouble();
        deliveryPartnerName = data?["deliveryPartnerName"] ?? "Delivery Partner";
        deliveryPartnerPhone = data?["deliveryPartnerPhone"] ?? "";
        orderStatus = data?["status"] ?? "processing";
        estimatedDelivery = data?["estimatedDelivery"] ?? "30-45 mins";

        // Enrich delivery address, payment method, and customer phone
        final Map<String, dynamic>? pres = (webDetails != null && webDetails!["prescription"] is Map)
            ? Map<String, dynamic>.from(webDetails!["prescription"])
            : null;
        final Map<String, dynamic>? ord = (webDetails != null && webDetails!["order"] is Map)
            ? Map<String, dynamic>.from(webDetails!["order"])
            : null;

        deliveryAddress =
            data?["customerAddress"]?.toString() ?? pres?["customerAddress"]?.toString() ?? data?["deliveryAddress"]?.toString() ?? data?["address"]?.toString();
        pharmacyAddress =
            data?["pharmacyAddress"]?.toString() ?? pres?["pharmacyAddress"]?.toString() ?? data?["pharmacy"]?.toString();
        paymentMethod =
            data?["paymentMethod"]?.toString() ?? pres?["paymentMethod"]?.toString() ?? ord?["paymentMethod"]?.toString();
        customerPhone =
            data?["customerPhone"]?.toString() ?? pres?["customerPhone"]?.toString() ?? data?["phone"]?.toString();

        // Debug logging
        print('🔍 [ORDER DETAILS] Loaded addresses:');
        print('  - Customer Address: $deliveryAddress');
        print('  - Pharmacy Address: $pharmacyAddress');
        print('  - Payment Method: $paymentMethod');
        print('  - Customer Phone: $customerPhone');
        print('  - Prescription data: $pres');
        print('  - Order data: $ord');

        loading = false;
      });
      
      // Calculate estimated delivery if we have location data
      _calculateEstimatedDelivery();
    } catch (e) {
      setState(() {
        loading = false;
      });
      _showErrorSnackBar("Failed to load order data");
    }
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _getCurrentLocation();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationPermissionDialog(
          "Location services are disabled",
          "Please enable location services in your device settings to track your order.",
          "Open Settings",
          () => Geolocator.openLocationSettings(),
        );
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationPermissionDialog(
            "Location permission denied",
            "Location access is required to track your order and show your location on the map.",
            "Grant Permission",
            () => Geolocator.openAppSettings(),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationPermissionDialog(
          "Location permission permanently denied",
          "Please enable location permissions in app settings to track your order.",
          "Open Settings",
          () => Geolocator.openAppSettings(),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      setState(() {
        _currentPosition = position;
      });
      
      // Update user location in the order data
      await apiService.updateUserLocation(
        position.latitude, 
        position.longitude
      );
      
      // Calculate real-time estimated delivery based on distance
      _calculateEstimatedDelivery();
      
      _showSuccessSnackBar("Location updated successfully");
    } catch (e) {
      print("Location error: $e");
      _showErrorSnackBar("Failed to get current location: $e");
    }
  }

  void _calculateEstimatedDelivery() {
    if (_currentPosition == null || customerLat == null || customerLng == null) {
      return;
    }

    // Calculate distance between delivery partner and customer
    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      customerLat!,
      customerLng!,
    );

    // Convert distance from meters to kilometers
    double distanceKm = distance / 1000;

    // Calculate estimated time based on distance
    // Assuming average speed of 30 km/h in city traffic
    double averageSpeedKmh = 30.0;
    double estimatedTimeHours = distanceKm / averageSpeedKmh;
    
    // Convert to minutes
    int estimatedTimeMinutes = (estimatedTimeHours * 60).round();
    
    // Add buffer time for traffic, stops, etc.
    int bufferMinutes = 10;
    int totalMinutes = estimatedTimeMinutes + bufferMinutes;
    
    // Format the estimated delivery time
    String timeString;
    if (totalMinutes < 60) {
      timeString = "$totalMinutes mins";
    } else {
      int hours = totalMinutes ~/ 60;
      int minutes = totalMinutes % 60;
      if (minutes == 0) {
        timeString = "${hours}h";
      } else {
        timeString = "${hours}h ${minutes}m";
      }
    }

    setState(() {
      estimatedDelivery = timeString;
    });

    print('🚚 [ESTIMATED DELIVERY] Distance: ${distanceKm.toStringAsFixed(2)} km');
    print('🚚 [ESTIMATED DELIVERY] Estimated time: $timeString');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLocationPermissionDialog(
    String title,
    String message,
    String buttonText,
    VoidCallback onPressed,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onPressed();
              },
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  LatLng _getMapCenter() {
    if (deliveryLat != null && deliveryLng != null) {
      return LatLng(deliveryLat!, deliveryLng!);
    } else if (customerLat != null && customerLng != null) {
      return LatLng(customerLat!, customerLng!);
    } else if (_currentPosition != null) {
      return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    }
    return const LatLng(7.2906, 80.6337); // Default to Sri Lanka
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];
    
    // Customer delivery address marker (destination)
    if (customerLat != null && customerLng != null) {
      markers.add(
        Marker(
          point: LatLng(customerLat!, customerLng!),
          width: 60,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.home,
                  color: Colors.white,
                  size: 28,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "DESTINATION",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Delivery partner location marker
    if (deliveryLat != null && deliveryLng != null) {
      markers.add(
        Marker(
          point: LatLng(deliveryLat!, deliveryLng!),
          width: 60,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.delivery_dining,
                  color: Colors.white,
                  size: 28,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "DELIVERY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Current user location marker (if available)
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 24,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.green.shade800,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "YOU",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildLegendItem(Color color, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 10,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deliveryPartnerName ?? "Delivery Partner",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Order Status: ${orderStatus?.toUpperCase() ?? 'PROCESSING'}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.access_time,
                    title: "Estimated Delivery",
                    value: estimatedDelivery ?? "30-45 mins",
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.phone,
                    title: "Contact",
                    value: deliveryPartnerPhone ?? "N/A",
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    String paymentLabel = '-';
    final raw = (paymentMethod ?? '').toLowerCase();
    if (raw.contains('cod') || raw.contains('cash')) {
      paymentLabel = 'Cash on Delivery';
    } else if ((paymentMethod ?? '').isNotEmpty) {
      paymentLabel = 'Card';
    }

    final String addr = (deliveryAddress ?? '').trim();
    final String pharmAddr = (pharmacyAddress ?? '').trim();
    final String phone = (customerPhone ?? '').trim();

    final bool hasAny = addr.isNotEmpty || pharmAddr.isNotEmpty || paymentLabel != '-' || phone.isNotEmpty;
    if (!hasAny) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            if (addr.isNotEmpty) Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Customer Address: $addr', style: const TextStyle(fontSize: 13))),
              ],
            ),
            if (addr.isNotEmpty) const SizedBox(height: 8),
            if (pharmAddr.isNotEmpty) Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_pharmacy, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Pharmacy Address: $pharmAddr', style: const TextStyle(fontSize: 13))),
              ],
            ),
            if (pharmAddr.isNotEmpty) const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.payment, color: Colors.deepPurple, size: 18),
              const SizedBox(width: 8),
              const Text('Payment: ', style: TextStyle(fontSize: 13, color: Colors.black87)),
              Text(paymentLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.phone, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Phone: $phone', style: const TextStyle(fontSize: 13))),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSteps() {
    final steps = [
      {"title": "Order Confirmed", "description": "Your order has been confirmed"},
      {"title": "Preparing", "description": "Medicines are being prepared"},
      {"title": "Dispatched", "description": "Order is on the way"},
      {"title": "Delivered", "description": "Order delivered successfully"},
    ];

    final currentStep = _getCurrentStepIndex();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Order Progress",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCompleted = index <= currentStep;
              final isCurrent = index == currentStep;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted ? Colors.green : Colors.grey[300],
                        border: isCurrent ? Border.all(color: Colors.blue, width: 2) : null,
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step["title"]!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isCompleted ? Colors.black : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step["description"]!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  int _getCurrentStepIndex() {
    switch (orderStatus?.toLowerCase()) {
      case 'processing':
        return 1;
      case 'dispatched':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Track Order"),
          centerTitle: true,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Order"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Map Section
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: _getMapCenter(),
                      initialZoom: 13,
                      minZoom: 10,
                      maxZoom: 18,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.curecart.app',
                      ),
                      MarkerLayer(markers: _buildMarkers()),
                    ],
                  ),
                  // Map Legend
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Map Legend",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildLegendItem(
                            Colors.green,
                            Icons.my_location,
                            "Your Location",
                          ),
                          const SizedBox(height: 4),
                          _buildLegendItem(
                            Colors.red,
                            Icons.delivery_dining,
                            "Delivery Partner",
                          ),
                          const SizedBox(height: 4),
                          _buildLegendItem(
                            Colors.blue,
                            Icons.home,
                            "Delivery Address",
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Status Card
          _buildStatusCard(),

          // Order details (address, payment, phone)
          _buildOrderDetailsCard(),
          
          // Progress Steps
          Expanded(
            child: SingleChildScrollView(
              child: _buildProgressSteps(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _getCurrentLocation,
        icon: const Icon(Icons.my_location),
        label: const Text("My Location"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}