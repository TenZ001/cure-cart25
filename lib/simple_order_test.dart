// file: lib/simple_order_test.dart
import 'package:flutter/material.dart';
import 'api_service.dart';

class SimpleOrderTest extends StatefulWidget {
  const SimpleOrderTest({Key? key}) : super(key: key);

  @override
  State<SimpleOrderTest> createState() => _SimpleOrderTestState();
}

class _SimpleOrderTestState extends State<SimpleOrderTest> {
  final ApiService _apiService = ApiService();
  String _testResult = '';
  bool _testing = false;

  Future<void> _testSimpleOrderFlow() async {
    setState(() {
      _testing = true;
      _testResult = 'Testing simple order flow...\n';
    });

    try {
      // Step 1: Check user
      final user = await _apiService.getUser();
      if (user == null) {
        _testResult += '❌ No user logged in\n';
        return;
      }
      _testResult += '✅ User: ${user['name']} (ID: ${user['id']})\n';

      // Step 2: Get pharmacies
      final pharmacies = await _apiService.getApprovedPharmacies();
      if (pharmacies.isEmpty) {
        _testResult += '❌ No pharmacies available\n';
        return;
      }
      _testResult += '✅ Found ${pharmacies.length} pharmacies\n';

      // Step 3: Create a simple test order
      final testItems = [
        {
          'name': 'Test Medicine - Simple Order',
          'qty': 1,
          'price': 50,
        }
      ];

      final selectedPharmacy = pharmacies.first;
      _testResult += '\n🛒 Creating test order:\n';
      _testResult += '  - Pharmacy: ${selectedPharmacy['name']} (ID: ${selectedPharmacy['_id']})\n';
      _testResult += '  - Items: ${testItems.map((item) => "${item['name']} x${item['qty']} @Rs.${item['price']}").join(", ")}\n';
      _testResult += '  - Total: Rs. 50\n';

      final orderResult = await _apiService.createOrder(
        items: testItems,
        pharmacyId: selectedPharmacy['_id'].toString(),
        address: 'Test Address - Simple Order',
        paymentMethod: 'cash',
        total: 50,
      );

      if (orderResult != null) {
        _testResult += '\n✅ ORDER CREATED SUCCESSFULLY!\n';
        _testResult += 'Order ID: ${orderResult['_id'] ?? orderResult['id']}\n';
        _testResult += 'Customer ID: ${orderResult['customerId']}\n';
        _testResult += 'Pharmacy ID: ${orderResult['pharmacyId']}\n';
        _testResult += 'Status: ${orderResult['status']}\n';
        _testResult += 'Total: ${orderResult['total']}\n';
        _testResult += '\n🎯 This order should now be visible in the pharmacist web interface!\n';
        _testResult += 'Check the web interface Orders tab to see if it appears.\n';
      } else {
        _testResult += '\n❌ FAILED TO CREATE ORDER\n';
      }
    } catch (e) {
      _testResult += '\n❌ ERROR: $e\n';
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
        title: const Text('Simple Order Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simple Order Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will create a simple test order and verify it appears in the web interface.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testing ? null : _testSimpleOrderFlow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _testing 
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Testing...'),
                      ],
                    )
                  : const Text('Create Test Order', style: TextStyle(fontSize: 16)),
              ),
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
                    _testResult.isEmpty ? 'Click "Create Test Order" to start...' : _testResult,
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

