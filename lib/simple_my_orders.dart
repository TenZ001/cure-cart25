// file: lib/simple_my_orders.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleMyOrdersPage extends StatefulWidget {
  const SimpleMyOrdersPage({Key? key}) : super(key: key);

  @override
  State<SimpleMyOrdersPage> createState() => _SimpleMyOrdersPageState();
}

class _SimpleMyOrdersPageState extends State<SimpleMyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
      print('📱 Loading orders from local storage...');
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedOrders = prefs.getStringList('user_orders') ?? [];
      
      final List<Map<String, dynamic>> allOrders = [];
      for (final orderString in savedOrders) {
        try {
          final order = jsonDecode(orderString) as Map<String, dynamic>;
          allOrders.add(order);
        } catch (e) {
          print('❌ Error parsing order: $e');
        }
      }
      
      print('📱 Loaded ${allOrders.length} orders from local storage');
      
      // Categorize orders - FIXED LOGIC
      final purchased = <Map<String, dynamic>>[];
      final pending = <Map<String, dynamic>>[];
      
      for (final order in allOrders) {
        final status = (order['status'] ?? 'pending').toString().toLowerCase();
        print('📋 Order status: $status for order: ${order['name']}');
        
        // NEW LOGIC: All orders go to purchased tab, none to pending
        // Pending tab is for orders that haven't been placed yet
        if (status == 'pending' || status == 'processing' || status == 'dispatched' || status == 'delivered') {
          purchased.add(order);
          print('✅ Added to purchased: ${order['name']} (status: $status)');
        } else {
          pending.add(order);
          print('⏳ Added to pending: ${order['name']} (status: $status)');
        }
      }

      setState(() {
        _purchasedOrders = purchased;
        _pendingOrders = pending;
        _loading = false;
      });
      
      print('✅ Categorized orders: ${purchased.length} purchased, ${pending.length} pending');
    } catch (e) {
      print('❌ Error loading orders: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  void _removePending(int index) {
    setState(() {
      _pendingOrders.removeAt(index);
    });
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
                                    // Navigator.push(
                                    //   context,
                                    //   MaterialPageRoute(
                                    //     builder: (_) => TrackOrderPage(orderId: orderId),
                                    //   ),
                                    // );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Order ID: $orderId')),
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
