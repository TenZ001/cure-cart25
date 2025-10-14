import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'prescription_details.dart';
import 'track_order.dart';

class MyPrescriptionScreen extends StatefulWidget {
  const MyPrescriptionScreen({Key? key}) : super(key: key);

  @override
  State<MyPrescriptionScreen> createState() => _MyPrescriptionScreenState();
}

class _MyPrescriptionScreenState extends State<MyPrescriptionScreen> {
  String _selectedFilter = 'All';
  bool _sortAscending = true;
  final ImagePicker _picker = ImagePicker();
  String _ocrResult = '';
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _prescriptions = [];
  List<Map<String, dynamic>> _filteredPrescriptions = [];
  Timer? _autoRefreshTimer;
  Map<String, bool> _orderPickedUpStatus = {}; // Cache for order pickup status

  bool _isTruthy(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = (v ?? '').toString().toLowerCase().trim();
    return s == 'true' || s == '1' || s == 'yes' || s == 'y' || s == 'placed' || s == 'order_placed' || s == 'order placed';
  }

  bool _isOrderPlaced(Map<String, dynamic> p) {
    try {
      if (_isTruthy(p['isPlaced']) || _isTruthy(p['orderPlaced']) || _isTruthy(p['isOrderPlaced']) || _isTruthy(p['placed']) || _isTruthy(p['placedOrder'])) {
        return true;
      }
      final action = (p['action'] ?? p['pharmacistAction'] ?? '').toString().toLowerCase();
      if (action.contains('place') && action.contains('order')) return true;
      final order = p['order'];
      if (order is Map<String, dynamic>) {
        if (_isTruthy(order['placed']) || _isTruthy(order['isPlaced']) || _isTruthy(order['orderPlaced'])) return true;
      }
    } catch (_) {}
    return false;
  }

  String _extractRawStatus(Map<String, dynamic> p) {
    String pick(dynamic v) => (v ?? '').toString().trim();
    String firstNonEmpty(List<dynamic> candidates) {
      for (final c in candidates) {
        final v = pick(c);
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    // Prefer order/fulfillment/pharmacy statuses over generic status
    final preferred = firstNonEmpty([
      p['orderStatus'],
      p['fulfillmentStatus'],
      p['pharmacyStatus'],
      p['pharmacistStatus'],
      p['deliveryStatus'],
      p['currentStatus'],
    ]);

    if (preferred.isNotEmpty) return preferred.toLowerCase();

    final generic = pick(p['status']);
    if (generic.isNotEmpty) return generic.toLowerCase();

    try {
      final order = p['order'];
      if (order is Map<String, dynamic>) {
        final s = pick(order['status']);
        if (s.isNotEmpty) return s.toLowerCase();
        final placed = pick(order['placed']);
        if (placed.toLowerCase() == 'true' || placed == '1') return 'placed';
      }
    } catch (_) {}

    try {
      final delivery = p['delivery'];
      if (delivery is Map<String, dynamic>) {
        final s = pick(delivery['status']);
        if (s.isNotEmpty) return s.toLowerCase();
      }
    } catch (_) {}

    return 'pending';
  }

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadPrescriptions();
    });
  }

  Future<void> _loadPrescriptions() async {
    final user = await _apiService.getUser();
    final String? customerId = user != null ? user['id'] as String? : null;
    if (customerId == null) {
      setState(() {
        _prescriptions = [];
        _filteredPrescriptions = [];
      });
      return;
    }
    
    // Clear pickup status cache when refreshing
    _orderPickedUpStatus.clear();
    final data = await _apiService.getPrescriptions(customerId);
    final mapped = data.map<Map<String, dynamic>>((p) {
      final createdAt = (p['createdAt'] ?? '').toString();
      final date = createdAt.contains('T') ? createdAt.split('T').first : createdAt;
      final id = (p['_id'] ?? '').toString();
      final shortId = id.isNotEmpty && id.length > 6 ? id.substring(id.length - 6) : id;
      // Normalize backend status → UI labels
      final rawStatus = _extractRawStatus(p);
      final placedFlag = _isOrderPlaced(p);
      String uiStatus;
      if (placedFlag ||
          rawStatus == 'processing' ||
          rawStatus == 'in_progress' ||
          rawStatus == 'in-progress' ||
          rawStatus == 'ordered' ||
          rawStatus == 'placed' ||
          rawStatus == 'order_placed' ||
          rawStatus == 'order placed') {
        uiStatus = 'Processing';
      } else if (rawStatus == 'approved') {
        uiStatus = 'Approved';
      } else if (rawStatus == 'rejected' || rawStatus == 'declined') {
        uiStatus = 'Declined';
      } else if (rawStatus == 'dispatched' || rawStatus == 'shipped' || rawStatus == 'dispatch') {
        uiStatus = 'Dispatched';
      } else if (rawStatus == 'delivered' || rawStatus == 'completed' || rawStatus == 'complete') {
        uiStatus = 'Delivered';
      } else {
        // includes 'pending' or missing status from mobile backend
        uiStatus = 'Submitted';
      }
      return {
        'id': id,
        'name': p['notes'] ?? 'Prescription $shortId',
        'status': uiStatus,
        'date': date,
        'imageUrl': p['imageUrl'],
        'ocrData': p['ocrData'],
        'raw': p,
      };
    }).toList();
    setState(() {
      _prescriptions = mapped;
      _filteredPrescriptions = List.from(_prescriptions);
      _filterAndSortPrescriptions();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickAndProcessImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final String apiKey = 'YOUR_VERYFI_API_KEY';
      final String url = 'https://api.veryfi.com/api/v8/partner/documents';

      var request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers['Authorization'] = 'apikey $apiKey'
        ..files.add(await http.MultipartFile.fromPath('file', image.path))
        ..fields['categories'] = 'medical';

      try {
        final response = await request.send();
        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          final decodedResponse = {
            'text': 'Sample text from OCR',
          }; // Placeholder
          setState(() {
            _ocrResult = decodedResponse['text'] ?? 'No text extracted';
            _prescriptions.add({
              'id': _prescriptions.length + 1,
              'status': 'Submitted',
              'date': DateTime.now().toIso8601String().split('T')[0],
              'image': image.path,
              'ocrData': _ocrResult,
            });
            _filterAndSortPrescriptions();
          });
        } else {
          setState(() {
            _ocrResult = 'Failed to process image';
          });
        }
      } catch (e) {
        setState(() {
          _ocrResult = 'Error: $e';
        });
      }
    }
  }

  void _filterAndSortPrescriptions() {
    setState(() {
      _filteredPrescriptions = List.from(
        _prescriptions.where((prescription) {
          if (_selectedFilter == 'All') return true;
          return prescription['status'] == _selectedFilter;
        }).toList(),
      );

      _filteredPrescriptions.sort((a, b) {
        DateTime dateA = DateTime.parse(a['date']);
        DateTime dateB = DateTime.parse(b['date']);
        return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      });
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFF85FF7A);
      case 'Declined':
        return Colors.red;
      case 'Processing':
        return const Color(0xFFdaaee0 ); // light purple
      case 'Dispatched':
        return Colors.lightBlueAccent;
      case 'Delivered':
        return Colors.greenAccent;
      case 'Submitted':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  void _onImageTap(Map<String, dynamic> prescription) {}

  Future<bool> _isOrderPickedUp(String orderId) async {
    if (_orderPickedUpStatus.containsKey(orderId)) {
      return _orderPickedUpStatus[orderId]!;
    }
    
    try {
      final orderDetails = await _apiService.getOrderDetailsWeb(orderId);
      if (orderDetails != null && orderDetails['order'] != null) {
        final order = orderDetails['order'] as Map<String, dynamic>;
        final tracking = order['tracking'] as Map<String, dynamic>?;
        final pickedUpAt = tracking?['pickedUpAt'];
        final isPickedUp = (pickedUpAt is String && pickedUpAt.isNotEmpty) || 
                         (pickedUpAt is DateTime) ||
                         (order['status'] == 'picked_up');
        
        _orderPickedUpStatus[orderId] = isPickedUp;
        return isPickedUp;
      }
    } catch (e) {
      print("Error checking pickup status: $e");
    }
    
    _orderPickedUpStatus[orderId] = false;
    return false;
  }

  Future<void> _savePrescription(Map<String, dynamic> prescription) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> saved = prefs.getStringList('saved_prescriptions') ?? [];

    final String id = (prescription['id'] ?? prescription['_id'] ?? '').toString();
    final bool alreadyExists = saved.any((s) {
      try {
        final m = jsonDecode(s);
        return (m['id'] ?? '').toString() == id && id.isNotEmpty;
      } catch (_) {
        return false;
      }
    });

    if (alreadyExists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already saved')),
        );
      }
      return;
    }

    final Map<String, dynamic> toSave = {
      'id': id,
      'name': prescription['name'] ?? 'Prescription',
      'status': prescription['status'] ?? 'Submitted',
      'date': prescription['date'] ?? '',
      'imageUrl': prescription['imageUrl'] ?? '',
      'ocrData': prescription['ocrData'] ?? '',
    };

    saved.add(jsonEncode(toSave));
    await prefs.setStringList('saved_prescriptions', saved);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription Saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('My Prescriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _pickAndProcessImage,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<String>(
                    value: _selectedFilter,
                    items: ['All', 'Approved', 'Declined', 'Submitted', 'Processing', 'Dispatched', 'Delivered'].map((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedFilter = newValue;
                          _filterAndSortPrescriptions();
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    ),
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                        _filterAndSortPrescriptions();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadPrescriptions,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _filteredPrescriptions.length,
                    itemBuilder: (context, index) {
                    final prescription = _filteredPrescriptions[index];
                      return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrescriptionDetailsScreen(
                              prescription: prescription,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 6,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Container(
                          height: 100,
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _onImageTap(prescription),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    bottomLeft: Radius.circular(10),
                                  ),
                                  child: (prescription['imageUrl'] != null &&
                                          (prescription['imageUrl'] as String)
                                              .toString()
                                              .isNotEmpty)
                                      ? Image.network(
                                          prescription['imageUrl'],
                                          width: 60,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.asset(
                                          'assets/icons/prescription_image.png',
                                          width: 60,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(prescription['name'] ?? 'Prescription'),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              prescription['status'],
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Status: ${prescription['status']}',
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        if (prescription['status'] == 'Dispatched' || prescription['status'] == 'Delivered')
                                          Padding(
                                            padding: const EdgeInsets.only(left: 6.0),
                                            child: ElevatedButton.icon(
                                              onPressed: (prescription['status'] == 'Delivered') ? null : () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => TrackOrderPage(
                                                      orderId: prescription['orderId'] ?? prescription['id'] ?? 'default-order',
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: Icon(
                                                prescription['status'] == 'Delivered' ? Icons.check_circle : Icons.track_changes, 
                                                size: 12
                                              ),
                                              label: Text(prescription['status'] == 'Delivered' ? 'Delivered' : 'Track'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: prescription['status'] == 'Delivered' ? Colors.grey : Colors.blue,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                textStyle: const TextStyle(fontSize: 10),
                                                minimumSize: const Size(60, 24),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text('Date: ${prescription['date']}'),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.bookmark_add_outlined),
                                    tooltip: 'Save',
                                    onPressed: () => _savePrescription(prescription),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: ""),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: "",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ""),
        ],
      ),
    );
  }
}
