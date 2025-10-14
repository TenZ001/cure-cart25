// file: lib/working_my_orders.dart
// lint: avoid_print
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'track_order.dart';

class WorkingMyOrdersPage extends StatefulWidget {
  const WorkingMyOrdersPage({Key? key}) : super(key: key);

  @override
  State<WorkingMyOrdersPage> createState() => _WorkingMyOrdersPageState();
}

class _WorkingMyOrdersPageState extends State<WorkingMyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _allOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Add a small delay to ensure any previous navigation has completed
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadOrders();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh orders when page becomes visible
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _normalizeStatus(String? status) {
    final s = (status ?? 'pending').toLowerCase();
    switch (s) {
      case 'ordered':
      case 'confirmed':
      case 'accepted':
      case 'confirm delivery':
      case 'confirm-delivery':
      case 'confirm_delivery':
      case 'delivery confirmed':
      case 'delivery-confirmed':
      case 'delivery_confirmed':
        return 'processing';
      case 'assigned':
      case 'out_for_delivery':
      case 'out-for-delivery':
      case 'out for delivery':
      case 'picked_up':
      case 'picked up':
      case 'pickedup':
        return 'dispatched';
      case 'completed':
        return 'delivered';
      default:
        return s;
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    
    try {
      // Get user info first
      final user = await _apiService.getUser();
      final String? customerId = user != null ? user['id'] as String? : null;
      
      if (customerId == null) {
        print('❌ No customer ID found, loading local orders only');
        // Still try to load local orders even without customer ID
      }

      // Load orders from local storage first (more reliable for mobile)
      print('📱 Loading orders from local storage...');
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedOrders = prefs.getStringList('user_orders') ?? [];
      
      final List<Map<String, dynamic>> localOrders = [];
      for (final orderString in savedOrders) {
        try {
          final order = jsonDecode(orderString) as Map<String, dynamic>;
          localOrders.add(order);
          print('📱 Local order: ${order['_id'] ?? order['id']}, Status: ${order['status']}, Name: ${order['name']}');
        } catch (e) {
          print('❌ Error parsing local order: $e');
        }
      }
      
      print('📱 Loaded ${localOrders.length} orders from local storage');
      
      // Try to load orders from API as well
      List<Map<String, dynamic>> apiOrders = [];
      if (customerId != null && customerId.isNotEmpty) {
        try {
          print('📱 Loading orders from API for customer: $customerId');
          apiOrders = await _apiService.getCustomerOrders(customerId);
          print('📱 Loaded ${apiOrders.length} orders from API');
        } catch (e) {
          print('❌ API orders failed, using local orders only: $e');
        }
      }
      
      // If no orders found, create a sample order for testing
      if (localOrders.isEmpty && apiOrders.isEmpty) {
        print('📱 No orders found, creating sample order for testing');
        final sampleOrder = {
          '_id': 'sample_${DateTime.now().millisecondsSinceEpoch}',
          'id': 'sample_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'Paracetamol 500mg',
          'price': 25,
          'qty': 2,
          'total': 50,
          'status': 'pending',
          'pharmacy': 'Test Pharmacy',
          'pharmacyId': 'test_pharmacy',
          'address': 'Test Address',
          'paymentMethod': 'cash',
          'createdAt': DateTime.now().toIso8601String(),
          'items': [
            {
              'name': 'Paracetamol 500mg',
              'quantity': 2,
              'price': 25,
            }
          ]
        };
        localOrders.add(sampleOrder);
        print('📱 Created sample order: ${sampleOrder['_id']}');
      }
      
      // Merge local + API orders by ID, preferring API status/details
      final Map<String, Map<String, dynamic>> idToOrder = {};
      
      // Seed with local orders
      for (final order in localOrders) {
        final orderId = order['_id']?.toString() ?? order['id']?.toString() ?? '';
        if (orderId.isEmpty) continue;
        idToOrder[orderId] = Map<String, dynamic>.from(order);
      }
      
      // Apply API updates (this is where status becomes "processing" after pharmacist confirms)
      for (final order in apiOrders) {
        final orderId = order['_id']?.toString() ?? order['id']?.toString() ?? '';
        if (orderId.isEmpty) continue;
        if (idToOrder.containsKey(orderId)) {
          final existing = idToOrder[orderId]!;
          // Update core fields from API where available
          if (order['status'] != null) existing['status'] = _normalizeStatus(order['status']);
          if (order['items'] is List) existing['items'] = order['items'];
          if (order['total'] != null) existing['total'] = order['total'];
          if (order['pharmacy'] != null) existing['pharmacy'] = order['pharmacy'];
          if (order['pharmacyId'] != null) existing['pharmacyId'] = order['pharmacyId'];
          if (order['address'] != null) existing['address'] = order['address'];
          if (order['paymentMethod'] != null) existing['paymentMethod'] = order['paymentMethod'];
          if (order['createdAt'] != null) existing['createdAt'] = order['createdAt'];
          existing['_id'] = orderId;
          existing['id'] = orderId;
        } else {
          // Try to re-associate any locally saved placeholder (id starts with 'local_')
          String? localKeyMatch;
          try {
            final apiTotal = order['total']?.toString();
            final apiItems = (order['items'] is List) ? (order['items'] as List) : const [];
            final String? apiFirstName = apiItems.isNotEmpty ? (apiItems.first['name']?.toString()) : (order['name']?.toString());
            for (final entry in idToOrder.entries) {
              final k = entry.key;
              if (!k.startsWith('local_')) continue;
              final local = entry.value;
              final localTotal = local['total']?.toString();
              final localItems = (local['items'] is List) ? (local['items'] as List) : const [];
              final String? localFirstName = localItems.isNotEmpty ? (localItems.first['name']?.toString()) : (local['name']?.toString());
              final bool totalMatches = apiTotal != null && localTotal != null && apiTotal == localTotal;
              final bool nameMatches = apiFirstName != null && localFirstName != null && apiFirstName.toLowerCase() == localFirstName.toLowerCase();
              if (totalMatches && nameMatches) {
                localKeyMatch = k;
                break;
              }
            }
          } catch (_) {}

          if (localKeyMatch != null) {
            final localOrder = idToOrder.remove(localKeyMatch!)!;
            localOrder['_id'] = orderId;
            localOrder['id'] = orderId;
            localOrder['status'] = _normalizeStatus(order['status']);
            if (order['items'] is List) localOrder['items'] = order['items'];
            if (order['pharmacy'] != null) localOrder['pharmacy'] = order['pharmacy'];
            if (order['pharmacyId'] != null) localOrder['pharmacyId'] = order['pharmacyId'];
            if (order['address'] != null) localOrder['address'] = order['address'];
            if (order['paymentMethod'] != null) localOrder['paymentMethod'] = order['paymentMethod'];
            if (order['createdAt'] != null) localOrder['createdAt'] = order['createdAt'];
            idToOrder[orderId] = localOrder;
          } else {
            idToOrder[orderId] = {
              ...order,
              '_id': orderId,
              'id': orderId,
              'status': _normalizeStatus(order['status']),
              // Ensure a display name exists
              'name': (order['items'] is List && (order['items'] as List).isNotEmpty)
                  ? ((order['items'] as List).first['name'] ?? order['name'] ?? 'Order')
                  : (order['name'] ?? 'Order'),
            };
          }
        }
      }
      
      // Build list from merged map
      final allOrders = idToOrder.values.toList();
      
      // Debug: Print all orders and their status
      print('🔍 DEBUG: Total orders found: ${allOrders.length}');
      for (final order in allOrders) {
        print('📋 Order: ${order['_id'] ?? order['id']}, Status: ${order['status']}, Name: ${order['name']}');
        print('📋 Order items: ${order['items']}');
        print('📋 Order total: ${order['total']}');
      }
      
      setState(() {
        _allOrders = allOrders;
        _loading = false;
      });
      
      // Persist merged orders so status changes (e.g., processing) stick locally
      try {
        final strings = allOrders.map((o) => jsonEncode(o)).toList();
        await prefs.setStringList('user_orders', strings);
      } catch (_) {}
      
      print('✅ Orders loaded successfully');
      print('📊 Purchased orders: ${_purchasedOrders.length}');
      print('📊 Pending orders: ${_pendingOrders.length}');
    } catch (e) {
      print('❌ Error loading orders: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _purchasedOrders {
    print('🔍 DEBUG: Checking purchased orders from ${_allOrders.length} total orders');
    final purchased = _allOrders.where((order) {
      final status = (order['status'] ?? 'pending').toString().toLowerCase();
      final isPurchased = status == 'pending' || status == 'processing' || status == 'dispatched' || status == 'delivered';
      print('📋 Order ${order['_id'] ?? order['id']}: status=$status, isPurchased=$isPurchased');
      return isPurchased;
    }).toList();
    print('✅ Purchased orders: ${purchased.length}');
    return purchased;
  }

  List<Map<String, dynamic>> get _pendingOrders {
    final pending = _allOrders.where((order) {
      final status = (order['status'] ?? 'pending').toString().toLowerCase();
      final isPending = status != 'pending' && status != 'processing' && status != 'dispatched' && status != 'delivered';
      print('📋 Order ${order['_id'] ?? order['id']}: status=$status, isPending=$isPending');
      return isPending;
    }).toList();
    print('⏳ Pending orders: ${pending.length}');
    return pending;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'dispatched':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'pending':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
      case 'dispatched':
        return Icons.local_shipping;
      case 'processing':
        return Icons.hourglass_empty;
      case 'pending':
        return Icons.shopping_bag;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Purchased"),
            Tab(text: "Pending"),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Purchased Orders Tab
                _purchasedOrders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text("No purchased orders yet"),
                            Text("Your purchased orders will appear here", 
                                 style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          itemCount: _purchasedOrders.length,
                          itemBuilder: (context, index) {
                            final order = _purchasedOrders[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Order Header
                                    Row(
                                      children: [
                                        Icon(
                                          _getStatusIcon(order['status']),
                                          color: _getStatusColor(order['status']),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Order #${(order['_id'] ?? order['id'] ?? 'Unknown').toString().substring(0, 8)}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                "Pharmacy: ${order['pharmacy'] ?? 'Unknown Pharmacy'}",
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                          color: _getStatusColor(order['status']),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                            order['status']?.toString().toUpperCase() ?? 'PENDING',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Order Items
                                    if (order['items'] != null && (order['items'] as List).isNotEmpty)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Ordered Items:",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...((order['items'] as List).map<Widget>((item) {
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[50],
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.grey[200]!),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[100],
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Icon(
                                                      Icons.medication,
                                                      color: Colors.blue,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          item['name'] ?? 'Unknown Medicine',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            Text(
                                                              "Qty: ${item['quantity'] ?? item['qty'] ?? 1}",
                                                              style: const TextStyle(
                                                                color: Colors.grey,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 16),
                                                            Text(
                                                              "Rs. ${item['price'] ?? 0}",
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.green,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList()),
                                        ],
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[200]!),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.blue[100],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.medication,
                                                color: Colors.blue,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    order['name'] ?? 'Unknown Medicine',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Qty: ${order['qty'] ?? 1}",
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Text(
                                                        "Rs. ${order['price'] ?? 0}",
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.green,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Order Summary
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue[200]!),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Total Amount:",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            "Rs. ${order['total'] ?? 0}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 12),
                                    
                                    // Order Date and Actions
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Ordered: ${DateTime.tryParse(order['createdAt'] ?? '')?.toString().split(' ')[0] ?? 'Unknown Date'}",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                  onPressed: () {
                                            final String orderId = (order['_id'] ?? order['id'] ?? 'demo').toString();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => TrackOrderPage(orderId: orderId),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.track_changes, size: 16),
                                          label: const Text("Track Order"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                // Pending Orders Tab
                _pendingOrders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text("No pending orders"),
                            Text("Your pending orders will appear here", 
                                 style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _pendingOrders.length,
                        itemBuilder: (context, index) {
                          final order = _pendingOrders[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: Icon(
                                _getStatusIcon(order['status']),
                                color: _getStatusColor(order['status']),
                                size: 40,
                              ),
                              title: Text(order['name'] ?? "Unknown"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Rs. ${order['price']} • Qty: ${order['qty'] ?? 1}"),
                                  Text("Pharmacy: ${order['pharmacy'] ?? 'No pharmacy'}"),
                                  if (order['total'] != null)
                                    Text("Total: Rs. ${order['total']}", 
                                         style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              trailing: Text(
                                order['status'] ?? 'pending',
                                style: TextStyle(
                                  color: _getStatusColor(order['status']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
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
