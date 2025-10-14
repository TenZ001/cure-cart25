// file: lib/test_complete_flow.dart
import 'package:flutter/material.dart';
import 'api_service.dart';

class TestCompleteFlow extends StatefulWidget {
  const TestCompleteFlow({Key? key}) : super(key: key);

  @override
  State<TestCompleteFlow> createState() => _TestCompleteFlowState();
}

class _TestCompleteFlowState extends State<TestCompleteFlow> {
  final ApiService _apiService = ApiService();
  String _testResult = '';
  bool _testing = false;

  Future<void> _testCompleteFlow() async {
    setState(() {
      _testing = true;
      _testResult = 'Testing complete order flow...\n';
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

      // Step 3: Create a test order
      final testItems = [
        {
          'name': 'Complete Flow Test Medicine',
          'qty': 1,
          'price': 75,
        }
      ];

      final selectedPharmacy = pharmacies.first;
      _testResult += '\n🛒 Creating test order:\n';
      _testResult += '  - Pharmacy: ${selectedPharmacy['name']} (ID: ${selectedPharmacy['_id']})\n';
      _testResult += '  - Items: ${testItems.map((item) => "${item['name']} x${item['qty']} @Rs.${item['price']}").join(", ")}\n';
      _testResult += '  - Total: Rs. 75\n';

      final orderResult = await _apiService.createOrder(
        items: testItems,
        pharmacyId: selectedPharmacy['_id'].toString(),
        address: 'Complete Flow Test Address',
        paymentMethod: 'cash',
        total: 75,
      );

      if (orderResult != null) {
        _testResult += '\n✅ ORDER CREATED SUCCESSFULLY!\n';
        _testResult += 'Order ID: ${orderResult['_id'] ?? orderResult['id']}\n';
        _testResult += 'Customer ID: ${orderResult['customerId']}\n';
        _testResult += 'Pharmacy ID: ${orderResult['pharmacyId']}\n';
        _testResult += 'Status: ${orderResult['status']}\n';
        _testResult += 'Total: ${orderResult['total']}\n';
        
        _testResult += '\n🎯 VERIFICATION STEPS:\n';
        _testResult += '1. Check mobile app - order should appear in "Purchased" tab\n';
        _testResult += '2. Check web interface - order should appear in Orders tab\n';
        _testResult += '3. Check console logs for detailed information\n';
        
        _testResult += '\n📱 MOBILE APP:\n';
        _testResult += '- Go to My Orders page\n';
        _testResult += '- Check "Purchased" tab\n';
        _testResult += '- Order should be visible with status "pending"\n';
        
        _testResult += '\n🌐 WEB INTERFACE:\n';
        _testResult += '- Login as pharmacist\n';
        _testResult += '- Go to Orders tab\n';
        _testResult += '- Order should be visible in the table\n';
        _testResult += '- Check console logs for order details\n';
        
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
        title: const Text('Test Complete Flow'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Complete Order Flow',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will create a test order and verify it appears in both mobile app and web interface.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testing ? null : _testCompleteFlow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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
                  : const Text('Test Complete Flow', style: TextStyle(fontSize: 16)),
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
                    _testResult.isEmpty ? 'Click "Test Complete Flow" to start...' : _testResult,
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
