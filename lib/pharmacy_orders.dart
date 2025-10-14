import 'package:flutter/material.dart';
import 'api_service.dart';

class PharmacyOrdersScreen extends StatefulWidget {
  const PharmacyOrdersScreen({Key? key}) : super(key: key);

  @override
  State<PharmacyOrdersScreen> createState() => _PharmacyOrdersScreenState();
}

class _PharmacyOrdersScreenState extends State<PharmacyOrdersScreen> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> orders = [];
  List<Map<String, dynamic>> deliveryPartners = [];
  bool loading = true;
  Map<String, dynamic>? selectedOrder;
  String selectedPartnerId = '';
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);
    try {
      // Load orders - you might need to implement getPharmacyOrders in ApiService
      final ordersData = await apiService.getPharmacyOrders();
      final partnersData = await apiService.getDeliveryPartners();
      
      // If no orders from API, create some test data
      if (ordersData.isEmpty) {
        orders = [
          {
            '_id': 'test_order_1',
            'total': 1500.0,
            'status': 'pending',
            'createdAt': DateTime.now().toIso8601String(),
            'deliveryPartnerId': null,
          },
          {
            '_id': 'test_order_2', 
            'total': 2300.0,
            'status': 'assigned',
            'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
            'deliveryPartnerId': 'partner_123',
          },
        ];
      } else {
        orders = ordersData;
      }
      
      // If no delivery partners from API, create some test data
      if (partnersData.isEmpty) {
        deliveryPartners = [
          {
            '_id': 'partner_123',
            'name': 'John Delivery',
            'contact': '+94 77 123 4567',
          },
          {
            '_id': 'partner_456', 
            'name': 'Sarah Transport',
            'contact': '+94 77 987 6543',
          },
        ];
      } else {
        deliveryPartners = partnersData;
      }
      
      setState(() {
        loading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => loading = false);
    }
  }

  Future<void> _assignDeliveryPartner() async {
    if (selectedOrder == null || selectedPartnerId.isEmpty) return;
    
    setState(() => isProcessing = true);
    try {
      final success = await apiService.assignDeliveryPartner(
        selectedOrder!['_id'], 
        selectedPartnerId
      );
      
      if (success) {
        // Update local state
        setState(() {
          orders = orders.map((order) => 
            order['_id'] == selectedOrder!['_id'] 
              ? {...order, 'deliveryPartnerId': selectedPartnerId, 'status': 'assigned'}
              : order
          ).toList();
        });
        
        _closeDialog();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery partner assigned successfully!'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to assign delivery partner'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  Future<void> _confirmOrder(String orderId) async {
    setState(() => isProcessing = true);
    try {
      final success = await apiService.confirmOrder(orderId);
      
      if (success) {
        setState(() {
          orders = orders.map((order) => 
            order['_id'] == orderId 
              ? {...order, 'status': 'confirmed'}
              : order
          ).toList();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order confirmed successfully!'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to confirm order'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  void _closeDialog() {
    setState(() {
      selectedOrder = null;
      selectedPartnerId = '';
    });
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'green';
      case 'assigned':
        return 'blue';
      case 'processing':
        return 'purple';
      case 'out_for_delivery':
        return 'yellow';
      case 'delivered':
        return 'green';
      default:
        return 'grey';
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'out_for_delivery':
        return 'dispatched';
      case 'processing':
        return 'processing';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final hasDeliveryPartner = order['deliveryPartnerId'] != null;
                  final canConfirm = hasDeliveryPartner && order['status'] != 'confirmed';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${order['_id']?.toString().substring(order['_id'].toString().length - 6) ?? 'N/A'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(order['status'] ?? 'pending') == 'green'
                                      ? Colors.green.shade100
                                      : _getStatusColor(order['status'] ?? 'pending') == 'blue'
                                          ? Colors.blue.shade100
                                          : _getStatusColor(order['status'] ?? 'pending') == 'purple'
                                              ? Colors.purple.shade100
                                              : _getStatusColor(order['status'] ?? 'pending') == 'yellow'
                                                  ? Colors.yellow.shade100
                                                  : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(order['status'] ?? 'pending'),
                                  style: TextStyle(
                                    color: _getStatusColor(order['status'] ?? 'pending') == 'green'
                                        ? Colors.green.shade800
                                        : _getStatusColor(order['status'] ?? 'pending') == 'blue'
                                            ? Colors.blue.shade800
                                            : _getStatusColor(order['status'] ?? 'pending') == 'purple'
                                                ? Colors.purple.shade800
                                                : _getStatusColor(order['status'] ?? 'pending') == 'yellow'
                                                    ? Colors.yellow.shade800
                                                    : Colors.grey.shade800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total: Rs. ${(order['total'] ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${DateTime.tryParse(order['createdAt'] ?? '')?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (hasDeliveryPartner) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.local_shipping,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Delivery Partner Assigned',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (!hasDeliveryPartner && 
                                  (order['status'] == 'pending' || order['status'] == 'processing')) ...[
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        selectedOrder = order;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: const Text(
                                      'Select Delivery Partner',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                              if (canConfirm) ...[
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isProcessing ? null : () => _confirmOrder(order['_id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      elevation: 3,
                                      shadowColor: Colors.green.withOpacity(0.3),
                                    ),
                                    child: Text(
                                      isProcessing ? 'Confirming...' : '✓ Confirm Order',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (order['status'] == 'confirmed') ...[
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green.shade300),
                                    ),
                                    child: const Text(
                                      '✓ Confirmed',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      // Delivery Partner Selection Dialog
      floatingActionButton: selectedOrder != null
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => _buildDeliveryPartnerDialog(),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_shipping, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Select Delivery Partner',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDeliveryPartnerDialog() {
    return AlertDialog(
      title: const Text('Select Delivery Partner'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedOrder != null) ...[
            Text(
              'Order: #${selectedOrder!['_id']?.toString().substring(selectedOrder!['_id'].toString().length - 6) ?? 'N/A'}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Total: Rs. ${(selectedOrder!['total'] ?? 0).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You must select a delivery partner before confirming the order',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (deliveryPartners.isEmpty)
            const Text('No delivery partners available')
          else
            DropdownButtonFormField<String>(
              value: selectedPartnerId.isEmpty ? null : selectedPartnerId,
              decoration: const InputDecoration(
                labelText: 'Select Delivery Partner',
                border: OutlineInputBorder(),
              ),
              items: deliveryPartners.map((partner) {
                return DropdownMenuItem<String>(
                  value: partner['_id'],
                  child: Text('${partner['name']} - ${partner['contact'] ?? 'No contact'}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPartnerId = value ?? '';
                });
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _closeDialog,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedPartnerId.isNotEmpty && !isProcessing
              ? _assignDeliveryPartner
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text(isProcessing ? 'Assigning...' : 'Assign & Enable Confirmation'),
        ),
      ],
    );
  }
}
