import 'package:flutter/material.dart';
import 'dart:ui';
import '../api_service.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> history = [];
  String? partnerId;
  bool loading = true;
  double totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Use delivery partner profile when available to identify partnerId
    final dp = await apiService.getDeliveryProfile();
    if (dp != null) {
      partnerId = (dp['_id']?.toString());
    } else {
      final user = await apiService.getUser();
      partnerId = user?["id"];
    }
    
    if (partnerId != null) {
      print('🔍 Loading delivery history for partner: $partnerId');
      history = await apiService.getDeliveryHistory(partnerId!);
      print('📦 Loaded ${history.length} delivery history items');
      // Calculate total earnings (Rs.150 per completed delivery)
      totalEarnings = history.length * 150.0;
    } else {
      print('❌ No partner ID found for delivery history');
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery History')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(
                children: [
                  // Earnings summary card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              Text('Rs. ${totalEarnings.toStringAsFixed(0)}', 
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              Text('${history.length} deliveries × Rs.150', 
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // History list
                  Expanded(
                    child: history.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No delivery history yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                                Text('Complete your first delivery to see it here', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final order = history[index];
                              final deliveredAt = order['deliveredAt'] ?? order['createdAt'];
                              final deliveryDate = deliveredAt != null ? DateTime.tryParse(deliveredAt.toString()) : null;
                              final orderTotal = order['total'] ?? 0.0;
                              
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
                                      child: ExpansionTile(
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                        ),
                                        title: Text(order['pharmacy'] ?? 'Pharmacy', 
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(order['address'] ?? 'No address'),
                                            const SizedBox(height: 4),
                                            // Show delivery date prominently
                                            if (deliveryDate != null) ...[
                                              Row(
                                                children: [
                                                  Icon(Icons.schedule, size: 14, color: Colors.blue.shade600),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Delivered: ${deliveryDate.day}/${deliveryDate.month}/${deliveryDate.year} at ${deliveryDate.hour.toString().padLeft(2, '0')}:${deliveryDate.minute.toString().padLeft(2, '0')}',
                                                    style: TextStyle(
                                                      color: Colors.blue.shade600,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                            ],
                                            Row(
                                              children: [
                                                Icon(Icons.monetization_on, size: 16, color: Colors.green.shade700),
                                                const SizedBox(width: 4),
                                                Text('Rs. 150', style: TextStyle(
                                                  color: Colors.green.shade700, 
                                                  fontWeight: FontWeight.bold
                                                )),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: (order['isCompleted'] == true) ? Colors.green.shade100 : Colors.orange.shade100,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    (order['isCompleted'] == true) ? 'Completed' : (order['status'] ?? 'assigned'), 
                                                    style: TextStyle(
                                                      color: (order['isCompleted'] == true) ? Colors.green.shade700 : Colors.orange.shade700, 
                                                      fontSize: 12, 
                                                      fontWeight: FontWeight.bold
                                                    )),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Delivery Details Section
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.blue.shade200),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(Icons.local_shipping, size: 16, color: Colors.blue.shade700),
                                                          const SizedBox(width: 8),
                                                          Text('Delivery Details', 
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.blue.shade700,
                                                              fontSize: 14
                                                            )),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      _buildDetailRow('Order ID', order['_id']?.toString().substring(0, 8) ?? 'N/A'),
                                                      _buildDetailRow('Delivered At', deliveryDate != null 
                                                        ? '${deliveryDate.day}/${deliveryDate.month}/${deliveryDate.year} at ${deliveryDate.hour.toString().padLeft(2, '0')}:${deliveryDate.minute.toString().padLeft(2, '0')}'
                                                        : 'N/A'),
                                                      _buildDetailRow('Order Total', 'Rs. ${orderTotal.toStringAsFixed(0)}'),
                                                      _buildDetailRow('Earnings', 'Rs. 150'),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                
                                                // Order Items Section
                                                if (order['items'] != null && (order['items'] as List).isNotEmpty) ...[
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange.shade50,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: Colors.orange.shade200),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Icon(Icons.shopping_bag, size: 16, color: Colors.orange.shade700),
                                                            const SizedBox(width: 8),
                                                            Text('Order Items', 
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.orange.shade700,
                                                                fontSize: 14
                                                              )),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 8),
                                                        ...((order['items'] as List).take(3).map((item) => 
                                                          _buildDetailRow(
                                                            item['name'] ?? 'Item', 
                                                            'Qty: ${item['quantity'] ?? 1} - Rs. ${(item['price'] ?? 0).toStringAsFixed(0)}'
                                                          )
                                                        )),
                                                        if ((order['items'] as List).length > 3)
                                                          Text('... and ${(order['items'] as List).length - 3} more items',
                                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                ],
                                                
                                                // Status and Earnings Summary
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.green.shade200),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text('Status: ${order['status'] ?? 'delivered'}', 
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.green.shade700
                                                            )),
                                                          Text('Earnings: Rs. 150', 
                                                            style: TextStyle(
                                                              color: Colors.green.shade600,
                                                              fontSize: 12
                                                            )),
                                                        ],
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                        decoration: BoxDecoration(
                                                          color: Colors.green.shade100,
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                                                            const SizedBox(width: 4),
                                                            Text('Completed', 
                                                              style: TextStyle(
                                                                color: Colors.green.shade700,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 12
                                                              )),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                        ),
                      ),
                    ),
                  );
                },
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _footer(context, 2),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/deliveryNotifications');
            break;
        }
      },
    );
  }
}