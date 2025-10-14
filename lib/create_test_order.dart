// file: lib/create_test_order.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CreateTestOrder extends StatefulWidget {
  const CreateTestOrder({Key? key}) : super(key: key);

  @override
  State<CreateTestOrder> createState() => _CreateTestOrderState();
}

class _CreateTestOrderState extends State<CreateTestOrder> {
  final ApiService _apiService = ApiService();
  String _result = '';
  bool _creating = false;

  Future<void> _createTestOrder() async {
    setState(() {
      _creating = true;
      _result = 'Creating test order...\n';
    });

    try {
      // Step 1: Get user and pharmacies
      final user = await _apiService.getUser();
      if (user == null) {
        _result += '❌ No user logged in\n';
        return;
      }
      _result += '✅ User: ${user['name']}\n';

      final pharmacies = await _apiService.getApprovedPharmacies();
      if (pharmacies.isEmpty) {
        _result += '❌ No pharmacies available\n';
        return;
      }
      _result += '✅ Found ${pharmacies.length} pharmacies\n';

      // Step 2: Create order via mobile API
      _result += '\n🛒 Creating order via mobile API...\n';
      
      final testItems = [
        {
          'name': 'Test Order - Web Display',
          'qty': 1,
          'price': 75,
        }
      ];

      final orderResult = await _apiService.createOrder(
        items: testItems,
        pharmacyId: pharmacies.first['_id'].toString(),
        address: 'Test Address for Web Display',
        paymentMethod: 'cash',
        total: 75,
      );

      if (orderResult == null) {
        _result += '❌ Failed to create order via mobile API\n';
        return;
      }

      _result += '✅ Order created via mobile API: ${orderResult['_id']}\n';

      // Step 3: Create order directly via web API
      _result += '\n🌐 Creating order via web API...\n';
      
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.webBaseUrl}/simple-orders/test'),
          headers: {
            'Content-Type': 'application/json',
          },
        );
        
        _result += '🌐 Web API response status: ${response.statusCode}\n';
        _result += '🌐 Web API response: ${response.body}\n';
        
        if (response.statusCode == 200) {
          _result += '✅ Order created via web API\n';
        } else {
          _result += '❌ Web API failed\n';
        }
      } catch (e) {
        _result += '❌ Web API error: $e\n';
      }

      // Step 4: Test web orders endpoint
      _result += '\n🔍 Testing web orders endpoint...\n';
      
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.webBaseUrl}/orders'),
          headers: {
            'Content-Type': 'application/json',
          },
        );
        
        _result += '🔍 Orders endpoint status: ${response.statusCode}\n';
        _result += '🔍 Orders endpoint response: ${response.body}\n';
        
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          _result += '✅ Orders endpoint returned ${data.length} orders\n';
          
          // Check if our orders are there
          final ourOrder = data.firstWhere(
            (order) => order['_id'] == orderResult['_id'],
            orElse: () => null,
          );
          
          if (ourOrder != null) {
            _result += '✅ Our order found in web orders!\n';
          } else {
            _result += '❌ Our order NOT found in web orders\n';
          }
        } else {
          _result += '❌ Orders endpoint failed\n';
        }
      } catch (e) {
        _result += '❌ Orders endpoint error: $e\n';
      }

      _result += '\n🎯 NEXT STEPS:\n';
      _result += '1. Check web interface Orders tab\n';
      _result += '2. Orders should appear in the table\n';
      _result += '3. If not visible, check console logs\n';
      _result += '4. Try refreshing the web page\n';

    } catch (e) {
      _result += '\n❌ Error: $e\n';
    } finally {
      setState(() {
        _creating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Test Order'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Test Order',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will create test orders via both mobile and web APIs to ensure they appear in the web interface.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _creating ? null : _createTestOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _creating 
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
                        Text('Creating...'),
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
                    _result.isEmpty ? 'Click "Create Test Order" to start...' : _result,
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
