import 'package:flutter/material.dart';
import 'dart:ui';
import '../api_service.dart';

class DeliveryNotificationsScreen extends StatefulWidget {
  const DeliveryNotificationsScreen({super.key});

  @override
  State<DeliveryNotificationsScreen> createState() => _DeliveryNotificationsScreenState();
}

class _DeliveryNotificationsScreenState extends State<DeliveryNotificationsScreen> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> notifications = [];
  String? partnerId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await apiService.getUser();
    partnerId = user?["id"];
    if (partnerId != null) {
      // Get assigned orders and create notifications
      final assigned = await apiService.getAssignedOrders(partnerId!);
      final history = await apiService.getDeliveryHistory(partnerId!);
      
      notifications = [];
      
      // Add notifications for assigned orders
      for (final order in assigned) {
        notifications.add({
          'type': 'assignment',
          'title': 'New Delivery Assignment',
          'message': 'You have been assigned a new delivery to ${order['pharmacy'] ?? 'Pharmacy'}',
          'orderId': order['_id'] ?? order['id'],
          'timestamp': DateTime.now(),
          'icon': Icons.assignment,
          'color': Colors.blue,
        });
      }
      
      // Add notifications for completed deliveries (earnings)
      for (final delivery in history) {
        notifications.add({
          'type': 'earnings',
          'title': 'Delivery Completed',
          'message': 'You earned Rs.150 for completing delivery to ${delivery['pharmacy'] ?? 'Pharmacy'}',
          'orderId': delivery['_id'] ?? delivery['id'],
          'timestamp': DateTime.now(),
          'icon': Icons.monetization_on,
          'color': Colors.green,
        });
      }
      
      // Sort by timestamp (newest first)
      notifications.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No notifications yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          Text('You\'ll see delivery assignments and earnings here', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (notification['color'] as Color).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      notification['icon'] as IconData,
                                      color: notification['color'] as Color,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    notification['title'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(notification['message'] as String),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${notification['timestamp']}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  trailing: notification['type'] == 'earnings'
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Rs. 150',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'New',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      bottomNavigationBar: _footer(context, 3),
    );
  }

  Widget _footer(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
      ],
      onTap: (i) {
        switch (i) {
          case 0:
            Navigator.pushReplacementNamed(context, '/deliveryDashboard');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/deliveryOrders');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/deliveryHistory');
            break;
          case 3:
            break;
        }
      },
    );
  }
}


