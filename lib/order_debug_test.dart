// file: lib/order_debug_test.dart
import 'package:flutter/material.dart';
import 'api_service.dart';

class OrderDebugTest extends StatefulWidget {
  const OrderDebugTest({Key? key}) : super(key: key);

  @override
  State<OrderDebugTest> createState() => _OrderDebugTestState();
}

class _OrderDebugTestState extends State<OrderDebugTest> {
  final ApiService _apiService = ApiService();
  String _debugResult = '';
  bool _testing = false;

  Future<void> _runDebugTest() async {
    setState(() {
      _testing = true;
      _debugResult = 'Running debug test...\n';
    });

    try {
      // Test 1: Check if user is logged in
      final user = await _apiService.getUser();
      if (user == null) {
        setState(() {
          _debugResult += '❌ No user logged in. Please login first.\n';
        });
        return;
      }
      _debugResult += '✅ User logged in: ${user['name']} (ID: ${user['id']})\n';

      // Test 2: Check if pharmacies are available
      final pharmacies = await _apiService.getApprovedPharmacies();
      if (pharmacies.isEmpty) {
        setState(() {
          _debugResult += '❌ No approved pharmacies available\n';
        });
        return;
      }
      _debugResult += '✅ Found ${pharmacies.length} approved pharmacies\n';
      _debugResult += '📋 Pharmacy details:\n';
      for (final pharmacy in pharmacies) {
        _debugResult += '  - ${pharmacy['name']} (ID: ${pharmacy['_id']})\n';
      }

      // Test 3: Create a test order
      final testItems = [
        {
          'name': 'Debug Test Medicine',
          'qty': 1,
          'price': 100,
        }
      ];

      final selectedPharmacy = pharmacies.first;
      _debugResult += '\n🛒 Creating test order for pharmacy: ${selectedPharmacy['name']} (ID: ${selectedPharmacy['_id']})\n';

      final orderResult = await _apiService.createOrder(
        items: testItems,
        pharmacyId: selectedPharmacy['_id'].toString(),
        address: 'Debug Test Address',
        paymentMethod: 'cash',
        total: 100,
      );

      if (orderResult != null) {
        _debugResult += '✅ Test order created successfully!\n';
        _debugResult += 'Order ID: ${orderResult['_id'] ?? orderResult['id']}\n';
        _debugResult += 'Order should now be visible to pharmacist in web interface\n';
        _debugResult += '\n📋 Order details:\n';
        _debugResult += '  - Customer ID: ${orderResult['customerId']}\n';
        _debugResult += '  - Pharmacy ID: ${orderResult['pharmacyId']}\n';
        _debugResult += '  - Status: ${orderResult['status']}\n';
        _debugResult += '  - Total: ${orderResult['total']}\n';
        _debugResult += '  - Items: ${orderResult['items']}\n';
      } else {
        _debugResult += '❌ Failed to create test order\n';
      }
    } catch (e) {
      setState(() {
        _debugResult += '❌ Error: $e\n';
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
        title: const Text('Order Debug Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDebugTest,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Debug Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This test will create a test order and help debug why orders are not showing in the pharmacist web interface.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _testing ? null : _runDebugTest,
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
                : const Text('Run Debug Test'),
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
                    _debugResult.isEmpty ? 'Click "Run Debug Test" to start debugging...' : _debugResult,
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
