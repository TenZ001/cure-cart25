// file: lib/test_web_orders.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TestWebOrders extends StatefulWidget {
  const TestWebOrders({Key? key}) : super(key: key);

  @override
  State<TestWebOrders> createState() => _TestWebOrdersState();
}

class _TestWebOrdersState extends State<TestWebOrders> {
  final ApiService _apiService = ApiService();
  String _testResult = '';
  bool _testing = false;

  Future<void> _testWebOrders() async {
    setState(() {
      _testing = true;
      _testResult = 'Testing web orders...\n';
    });

    try {
      // Step 1: Create a test order
      _testResult += '🛒 Creating test order...\n';
      
      final testItems = [
        {
          'name': 'Web Test Medicine',
          'qty': 1,
          'price': 100,
        }
      ];

      final user = await _apiService.getUser();
      if (user == null) {
        _testResult += '❌ No user logged in\n';
        return;
      }

      final pharmacies = await _apiService.getApprovedPharmacies();
      if (pharmacies.isEmpty) {
        _testResult += '❌ No pharmacies available\n';
        return;
      }

      final orderResult = await _apiService.createOrder(
        items: testItems,
        pharmacyId: pharmacies.first['_id'].toString(),
        address: 'Web Test Address',
        paymentMethod: 'cash',
        total: 100,
      );

      if (orderResult == null) {
        _testResult += '❌ Failed to create order\n';
        return;
      }

      _testResult += '✅ Order created: ${orderResult['_id']}\n';

      // Step 2: Test web API directly
      _testResult += '\n🌐 Testing web API...\n';
      
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.webBaseUrl}/orders'),
          headers: {
            'Content-Type': 'application/json',
          },
        );
        
        _testResult += '🌐 Web API response status: ${response.statusCode}\n';
        _testResult += '🌐 Web API response body: ${response.body}\n';
        
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          _testResult += '✅ Web API returned ${data.length} orders\n';
          
          // Check if our order is in the response
          final ourOrder = data.firstWhere(
            (order) => order['_id'] == orderResult['_id'],
            orElse: () => null,
          );
          
          if (ourOrder != null) {
            _testResult += '✅ Our order found in web API!\n';
            _testResult += '  - Order ID: ${ourOrder['_id']}\n';
            _testResult += '  - Status: ${ourOrder['status']}\n';
            _testResult += '  - Total: ${ourOrder['total']}\n';
            _testResult += '  - Pharmacy: ${ourOrder['pharmacy']}\n';
          } else {
            _testResult += '❌ Our order NOT found in web API\n';
          }
        } else {
          _testResult += '❌ Web API failed with status ${response.statusCode}\n';
        }
      } catch (e) {
        _testResult += '❌ Web API error: $e\n';
      }

      // Step 3: Test simple orders endpoint
      _testResult += '\n🔧 Testing simple orders endpoint...\n';
      
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.webBaseUrl}/simple-orders'),
          headers: {
            'Content-Type': 'application/json',
          },
        );
        
        _testResult += '🔧 Simple orders response status: ${response.statusCode}\n';
        _testResult += '🔧 Simple orders response body: ${response.body}\n';
        
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          _testResult += '✅ Simple orders returned ${data.length} orders\n';
        } else {
          _testResult += '❌ Simple orders failed with status ${response.statusCode}\n';
        }
      } catch (e) {
        _testResult += '❌ Simple orders error: $e\n';
      }

      _testResult += '\n🎯 VERIFICATION:\n';
      _testResult += '1. Check web interface Orders tab\n';
      _testResult += '2. Order should appear in the table\n';
      _testResult += '3. Check console logs for details\n';

    } catch (e) {
      _testResult += '\n❌ General error: $e\n';
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
        title: const Text('Test Web Orders'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Web Orders',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will create a test order and verify it appears in the web interface.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testing ? null : _testWebOrders,
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
                  : const Text('Test Web Orders', style: TextStyle(fontSize: 16)),
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
                    _testResult.isEmpty ? 'Click "Test Web Orders" to start...' : _testResult,
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
