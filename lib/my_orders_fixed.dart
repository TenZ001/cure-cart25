// file: lib/my_orders_fixed.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'track_order.dart';

class MyOrdersPageFixed extends StatefulWidget {
  const MyOrdersPageFixed({Key? key}) : super(key: key);

  @override
  State<MyOrdersPageFixed> createState() => _MyOrdersPageFixedState();
}

class _MyOrdersPageFixedState extends State<MyOrdersPageFixed>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _purchasedOrders = [];
  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _allOrders = [];
  Timer? _autoRefreshTimer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
    // Auto-refresh every 15 seconds like prescriptions
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    
    try {
      // Get user info
      final user = await _apiService.getUser();
      final String? customerId = user != null ? user['id'] as String? : null;
      
      if (customerId == null) {
        setState(() {
          _purchasedOrders = [];
          _pendingOrders = [];
          _allOrders = [];
          _loading = false;
        });
        return;
      }

      // Load orders from API (we'll need to add this method to ApiService)
      final apiOrders = await _loadOrdersFromAPI(customerId);
      
      // Load orders from local storage as backup
      final localOrders = await _loadLocalOrders();
      
      // Combine and deduplicate orders
      final allOrders = <Map<String, dynamic>>[];
      final orderIds = <String>{};
      
      // Add API orders first (they're more up-to-date)
      for (final order in apiOrders) {
        final orderId = order['id']?.toString() ?? order['_id']?.toString() ?? '';
        if (orderId.isNotEmpty && !orderIds.contains(orderId)) {
          orderIds.add(orderId);
          allOrders.add(order);
        }
      }
      
      // Add local orders that aren't already in API orders
      for (final order in localOrders) {
        final orderId = order['id']?.toString() ?? order['_id']?.toString() ?? '';
        if (orderId.isNotEmpty && !orderIds.contains(orderId)) {
          orderIds.add(orderId);
          allOrders.add(order);
        }
      }

      // Categorize orders
      final purchased = <Map<String, dynamic>>[];
      final pending = <Map<String, dynamic>>[];
      
      for (final order in allOrders) {
        final status = (order['status'] ?? 'pending').toString().toLowerCase();
        if (status == 'pending' || status == 'processing' || status == 'dispatched' || status == 'delivered') {
          purchased.add(order);
        } else {
          pending.add(order);
        }
      }

      setState(() {
        _allOrders = allOrders;
        _purchasedOrders = purchased;
        _pendingOrders = pending;
        _loading = false;
      });
      
      print('✅ Loaded ${allOrders.length} orders: ${purchased.length} purchased, ${pending.length} pending');
    } catch (e) {
      print('❌ Error loading orders: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadOrdersFromAPI(String customerId) async {
    try {
      print('📡 Loading orders from API for customer: $customerId');
      final orders = await _apiService.getCustomerOrders(customerId);
      print('📡 Loaded ${orders.length} orders from API');
      return orders;
    } catch (e) {
      print('❌ Error loading orders from API: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadLocalOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedOrders = prefs.getStringList('user_orders') ?? [];
      
      final List<Map<String, dynamic>> orders = [];
      for (final orderString in savedOrders) {
        try {
          final order = jsonDecode(orderString) as Map<String, dynamic>;
          orders.add(order);
        } catch (e) {
          print('❌ Error parsing local order: $e');
        }
      }
      
      print('📱 Loaded ${orders.length} local orders');
      return orders;
    } catch (e) {
      print('❌ Error loading local orders: $e');
      return [];
    }
  }

  Future<void> _removePending(int index) async {
    try {
      final order = _pendingOrders[index];
      final orderId = order['id']?.toString() ?? order['_id']?.toString() ?? '';
      
      if (orderId.isNotEmpty) {
        // Try to delete from server first
        final deleted = await _apiService.deleteOrderWeb(orderId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(deleted ? 'Order deleted successfully' : 'Order removed locally'),
              backgroundColor: deleted ? Colors.green : Colors.orange,
            ),
          );
        }
      }
      
      // Remove from local state
      setState(() {
        _pendingOrders.removeAt(index);
        _allOrders = _allOrders.where((o) => (o['id']?.toString() ?? o['_id']?.toString() ?? '') != orderId).toList();
      });
      
      // Save to local storage
      await _saveLocalOrders();
    } catch (e) {
      print('❌ Error removing pending order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error removing order. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveLocalOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allOrders = [..._purchasedOrders, ..._pendingOrders];
      final strings = allOrders.map((o) => jsonEncode(o)).toList();
      await prefs.setStringList('user_orders', strings);
    } catch (e) {
      print('❌ Error saving local orders: $e');
    }
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
                // Purchased Orders
                _purchasedOrders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text("No purchased orders yet"),
                            Text("Your orders will appear here after purchase", 
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
                              child: ListTile(
                                leading: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
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
                                    if (order['status'] != null)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(order['status']),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          "Status: ${order['status']}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(),
                                  onPressed: () {
                                    final String orderId = (order['id'] ?? order['_id'] ?? 'demo').toString();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TrackOrderPage(orderId: orderId),
                                      ),
                                    );
                                  },
                                  child: const Text("Track Order"),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                // Pending Orders
                _pendingOrders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pending_actions, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text("No pending orders"),
                            Text("Pending orders will appear here", 
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
                              leading: const Icon(
                                Icons.pending,
                                color: Colors.orange,
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
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removePending(index),
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
