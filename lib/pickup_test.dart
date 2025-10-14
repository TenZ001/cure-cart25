import 'package:flutter/material.dart';
import 'api_service.dart';

class PickupTestScreen extends StatefulWidget {
  final String orderId;
  const PickupTestScreen({super.key, required this.orderId});

  @override
  State<PickupTestScreen> createState() => _PickupTestScreenState();
}

class _PickupTestScreenState extends State<PickupTestScreen> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? orderDetails;
  bool loading = true;
  bool isPickedUp = false;

  @override
  void initState() {
    super.initState();
    _checkPickupStatus();
  }

  Future<void> _checkPickupStatus() async {
    try {
      final details = await apiService.getOrderDetailsWeb(widget.orderId);
      setState(() {
        orderDetails = details;
        if (details != null && details['order'] != null) {
          final order = details['order'] as Map<String, dynamic>;
          final tracking = order['tracking'] as Map<String, dynamic>?;
          final pickedUpAt = tracking?['pickedUpAt'];
          isPickedUp = (pickedUpAt is String && pickedUpAt.isNotEmpty) || 
                      (pickedUpAt is DateTime) ||
                      (order['status'] == 'picked_up');
        }
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pickup Status Test"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Order Pickup Status",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (loading)
                      const CircularProgressIndicator()
                    else ...[
                      Text("Order ID: ${widget.orderId}"),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            isPickedUp ? Icons.check_circle : Icons.schedule,
                            color: isPickedUp ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isPickedUp ? "Order Picked Up" : "Order Not Picked Up",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isPickedUp ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      if (orderDetails != null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          "Order Details:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text("Status: ${orderDetails!['order']?['status'] ?? 'Unknown'}"),
                        if (orderDetails!['order']?['tracking'] != null) ...[
                          const SizedBox(height: 4),
                          Text("Picked Up At: ${orderDetails!['order']?['tracking']?['pickedUpAt'] ?? 'Not set'}"),
                        ],
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkPickupStatus,
                child: const Text("Refresh Status"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
