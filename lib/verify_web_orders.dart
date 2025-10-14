// file: lib/verify_web_orders.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VerifyWebOrders extends StatefulWidget {
  const VerifyWebOrders({Key? key}) : super(key: key);

  @override
  State<VerifyWebOrders> createState() => _VerifyWebOrdersState();
}

class _VerifyWebOrdersState extends State<VerifyWebOrders> {
  String _result = '';
  bool _testing = false;

  Future<void> _verifyWebOrders() async {
    setState(() {
      _testing = true;
      _result = 'Verifying web orders...\n';
    });

    try {
      // Test 1: Check if web server is running
      _result += '🌐 Testing web server...\n';
      
      try {
        final response = await http.get(
          Uri.parse('http://localhost:5000/api/orders'),
          headers: {
            'Content-Type': 'application/json',
          },
        );
        
        _result += '🌐 Web server response: ${response.statusCode}\n';
        _result += '🌐 Response body: ${response.body}\n';
        
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          _result += '✅ Web server is running and returned ${data.length} orders\n';
          
          if (data.isNotEmpty) {
            _result += '📦 Sample order:\n';
            _result += '  - ID: ${data[0]['_id']}\n';
            _result += '  - Pharmacy: ${data[0]['pharmacy']}\n';
            _result += '  - Status: ${data[0]['status']}\n';
            _result += '  - Total: ${data[0]['total']}\n';
          }
        } else {
          _result += '❌ Web server returned error: ${response.statusCode}\n';
        }
      } catch (e) {
        _result += '❌ Web server error: $e\n';
        _result += '💡 Make sure the web server is running on port 5000\n';
      }

      // Test 2: Check simple orders endpoint
      _result += '\n🔧 Testing simple orders endpoint...\n';
      
      try {
        final response = await http.get(
          Uri.parse('http://localhost:5000/api/simple-orders'),
          headers: {
            'Content-Type': 'application/json',
          },
        );
        
        _result += '🔧 Simple orders response: ${response.statusCode}\n';
        _result += '🔧 Simple orders body: ${response.body}\n';
        
        if (response.statusCode == 200) {
          _result += '✅ Simple orders endpoint is working\n';
        } else {
          _result += '❌ Simple orders endpoint failed\n';
        }
      } catch (e) {
        _result += '❌ Simple orders error: $e\n';
      }

      // Test 3: Create a test order
      _result += '\n🧪 Creating test order...\n';
      
      try {
        final response = await http.post(
          Uri.parse('http://localhost:5000/api/simple-orders/test'),
          headers: {
            'Content-Type': 'application/json',
          },
        );
        
        _result += '🧪 Test order response: ${response.statusCode}\n';
        _result += '🧪 Test order body: ${response.body}\n';
        
        if (response.statusCode == 200) {
          _result += '✅ Test order created successfully\n';
        } else {
          _result += '❌ Test order creation failed\n';
        }
      } catch (e) {
        _result += '❌ Test order error: $e\n';
      }

      _result += '\n🎯 VERIFICATION STEPS:\n';
      _result += '1. Check web interface at http://localhost:3000\n';
      _result += '2. Login as pharmacist\n';
      _result += '3. Go to Orders tab\n';
      _result += '4. Orders should be visible in the table\n';
      _result += '5. If not visible, check browser console for errors\n';

    } catch (e) {
      _result += '\n❌ General error: $e\n';
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
        title: const Text('Verify Web Orders'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verify Web Orders',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will test the web server and verify orders are accessible via the web interface.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testing ? null : _verifyWebOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
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
                        Text('Verifying...'),
                      ],
                    )
                  : const Text('Verify Web Orders', style: TextStyle(fontSize: 16)),
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
                    _result.isEmpty ? 'Click "Verify Web Orders" to start...' : _result,
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
