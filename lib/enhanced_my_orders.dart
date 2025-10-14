// file: lib/enhanced_my_orders.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'track_order.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EnhancedMyOrdersPage extends StatefulWidget {
  const EnhancedMyOrdersPage({Key? key}) : super(key: key);

  @override
  State<EnhancedMyOrdersPage> createState() => _EnhancedMyOrdersPageState();
}

class _EnhancedMyOrdersPageState extends State<EnhancedMyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _purchasedOrders = [];
  List<Map<String, dynamic>> _pendingOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    
    try {
      // Load orders from local storage first
      await _loadLocalOrders();
      
      // Try to load orders from API
      final user = await _apiService.getUser();
      if (user != null) {
        // For now, we'll use local orders since API orders are managed by pharmacists
        // In the future, we could add an endpoint to get customer orders
        print('📱 Loaded ${_purchasedOrders.length} purchased orders and ${_pendingOrders.length} pending orders');
      }
    } catch (e) {
      print('❌ Error loading orders: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadLocalOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedOrders = prefs.getStringList('user_orders') ?? [];
      
      final List<Map<String, dynamic>> purchased = [];
      final List<Map<String, dynamic>> pending = [];
      
      for (final orderString in savedOrders) {
        try {
          final order = jsonDecode(orderString) as Map<String, dynamic>;
          final status = order['status']?.toString().toLowerCase() ?? 'pending';
          
          if (status == 'pending' || status == 'processing' || status == 'dispatched' || status == 'delivered') {
            purchased.add(order);
          } else {
            pending.add(order);
          }
        } catch (e) {
          print('❌ Error parsing order: $e');
        }
      }
      
      setState(() {
        _purchasedOrders = purchased;
        _pendingOrders = pending;
      });
    } catch (e) {
      print('❌ Error loading local orders: $e');
    }
  }

  Future<void> _removePending(int index) async {
    try {
      final order = _pendingOrders[index];
      final orderId = order['id']?.toString() ?? order['_id']?.toString() ?? '';
      
      if (orderId.isNotEmpty) {
        // Try to delete from server first
        final apiService = ApiService();
        final deleted = await apiService.deleteOrderWeb(orderId);
        
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
