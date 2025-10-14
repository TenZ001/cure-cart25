// file: lib/order_flow_test.dart
import 'package:flutter/material.dart';
import 'api_service.dart';

class OrderFlowTest extends StatefulWidget {
  const OrderFlowTest({Key? key}) : super(key: key);

  @override
  State<OrderFlowTest> createState() => _OrderFlowTestState();
}

class _OrderFlowTestState extends State<OrderFlowTest> {
  final ApiService _apiService = ApiService();
  String _testResult = '';
  bool _testing = false;

  Future<void> _testOrderFlow() async {
    setState(() {
      _testing = true;
      _testResult = 'Testing order flow...\n';
    });

    try {
      // Test 1: Check if user is logged in
      final user = await _apiService.getUser();
      if (user == null) {
        setState(() {
          _testResult += '❌ No user logged in. Please login first.\n';
        });
        return;
      }
      _testResult += '✅ User logged in: ${user['name']}\n';

      // Test 2: Check if pharmacies are available
      final pharmacies = await _apiService.getApprovedPharmacies();
      if (pharmacies.isEmpty) {
        setState(() {
          _testResult += '❌ No approved pharmacies available\n';
        });
        return;
      }
      _testResult += '✅ Found ${pharmacies.length} approved pharmacies\n';

      // Test 3: Create a test order
      final testItems = [
        {
          'name': 'Test Medicine',
          'qty': 1,
          'price': 100,
        }
      ];

      final orderResult = await _apiService.createOrder(
        items: testItems,
        pharmacyId: pharmacies.first['_id'].toString(),
        address: 'Test Address',
        paymentMethod: 'cash',
        total: 100,
      );

      if (orderResult != null) {
        _testResult += '✅ Test order created successfully!\n';
        _testResult += 'Order ID: ${orderResult['_id'] ?? orderResult['id']}\n';
        _testResult += '✅ Order should now be visible to pharmacist in web interface\n';
      } else {
        _testResult += '❌ Failed to create test order\n';
      }
    } catch (e) {
      setState(() {
        _testResult += '❌ Error: $e\n';
      });
    } finally {
      setState(() {
        _testing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Flow Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Flow Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This test will verify that orders created in the mobile app are properly sent to the web API and will be visible to pharmacists.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _testing ? null : _testOrderFlow,
              child: _testing 
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Testing...'),
                    ],
                  )
                : const Text('Run Test'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResult.isEmpty ? 'Click "Run Test" to start testing...' : _testResult,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
