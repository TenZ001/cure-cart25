// file: lib/debug_api_orders.dart
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DebugApiOrders extends StatefulWidget {
  const DebugApiOrders({Key? key}) : super(key: key);

  @override
  State<DebugApiOrders> createState() => _DebugApiOrdersState();
}

class _DebugApiOrdersState extends State<DebugApiOrders> {
  final ApiService _apiService = ApiService();
  String _debugResult = '';
  bool _testing = false;

  Future<void> _debugApiCalls() async {
    setState(() {
      _testing = true;
      _debugResult = 'Debugging API calls...\n';
    });

    try {
      // Step 1: Check user
      final user = await _apiService.getUser();
      if (user == null) {
        _debugResult += '❌ No user logged in\n';
        return;
      }
      _debugResult += '✅ User: ${user['name']} (ID: ${user['id']})\n';

      // Step 2: Test direct API call
      final customerId = user['id'];
      _debugResult += '\n🔍 Testing direct API calls:\n';
      
      // Test web API
      try {
        final token = await _apiService.getToken();
        final headers = <String, String>{};
        if (token != null && token.isNotEmpty) {
          headers["Authorization"] = "Bearer $token";
          headers["Accept"] = "application/json";
        }

        final webUrl = Uri.parse("${ApiConfig.webBaseUrl}/orders/customer/$customerId");
        _debugResult += '🌐 Web API URL: $webUrl\n';
        _debugResult += '🌐 Headers: $headers\n';
        
        final response = await http.get(webUrl, headers: headers.isEmpty ? null : headers);
        _debugResult += '🌐 Response status: ${response.statusCode}\n';
        _debugResult += '🌐 Response body: ${response.body}\n';
        
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          _debugResult += '✅ Web API returned ${data.length} orders\n';
          for (final order in data) {
            _debugResult += '  - Order ID: ${order['_id']}, Status: ${order['status']}, Total: ${order['total']}\n';
          }
        } else {
          _debugResult += '❌ Web API failed with status ${response.statusCode}\n';
        }
      } catch (e) {
        _debugResult += '❌ Web API error: $e\n';
      }

      // Test backend API
      try {
        final backendUrl = Uri.parse("${ApiConfig.baseUrl}/orders/customer/$customerId");
        _debugResult += '\n🔧 Backend API URL: $backendUrl\n';
        
        final response = await http.get(backendUrl);
        _debugResult += '🔧 Response status: ${response.statusCode}\n';
        _debugResult += '🔧 Response body: ${response.body}\n';
        
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          _debugResult += '✅ Backend API returned ${data.length} orders\n';
        } else {
          _debugResult += '❌ Backend API failed with status ${response.statusCode}\n';
        }
      } catch (e) {
        _debugResult += '❌ Backend API error: $e\n';
      }

      // Step 3: Test ApiService method
      _debugResult += '\n📱 Testing ApiService.getCustomerOrders():\n';
      try {
        final orders = await _apiService.getCustomerOrders(customerId);
        _debugResult += '📱 ApiService returned ${orders.length} orders\n';
        for (final order in orders) {
          _debugResult += '  - Order ID: ${order['_id']}, Status: ${order['status']}, Total: ${order['total']}\n';
        }
      } catch (e) {
        _debugResult += '❌ ApiService error: $e\n';
      }

    } catch (e) {
      _debugResult += '\n❌ General error: $e\n';
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
        title: const Text('Debug API Orders'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug API Orders',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will test all API calls to see why orders are not loading.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testing ? null : _debugApiCalls,
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
                        Text('Debugging...'),
                      ],
                    )
                  : const Text('Debug API Calls', style: TextStyle(fontSize: 16)),
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
                    _debugResult.isEmpty ? 'Click "Debug API Calls" to start...' : _debugResult,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
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

