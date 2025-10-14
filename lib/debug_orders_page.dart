// file: lib/debug_orders_page.dart
import 'package:flutter/material.dart';
import 'simple_order_test.dart';
import 'order_debug_test.dart';
import 'debug_api_orders.dart';
import 'test_complete_flow.dart';
import 'test_web_orders.dart';
import 'create_test_order.dart';
import 'verify_web_orders.dart';

class DebugOrdersPage extends StatefulWidget {
  const DebugOrdersPage({Key? key}) : super(key: key);

  @override
  State<DebugOrdersPage> createState() => _DebugOrdersPageState();
}

class _DebugOrdersPageState extends State<DebugOrdersPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Orders'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Orders',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Use these tools to debug why orders are not showing in the web interface.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            
            // Simple Order Test
            Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_cart, color: Colors.blue),
                title: const Text('Simple Order Test'),
                subtitle: const Text('Create a test order and verify it appears in web'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SimpleOrderTest(),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Order Debug Test
            Card(
              child: ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.orange),
                title: const Text('Order Debug Test'),
                subtitle: const Text('Detailed debugging of order creation and API calls'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderDebugTest(),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Debug API Orders
            Card(
              child: ListTile(
                leading: const Icon(Icons.api, color: Colors.purple),
                title: const Text('Debug API Orders'),
                subtitle: const Text('Test API calls to see why orders are not loading'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DebugApiOrders(),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Complete Flow
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Test Complete Flow'),
                subtitle: const Text('Create order and verify it appears in both mobile and web'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TestCompleteFlow(),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Web Orders
            Card(
              child: ListTile(
                leading: const Icon(Icons.web, color: Colors.blue),
                title: const Text('Test Web Orders'),
                subtitle: const Text('Test web API and verify orders appear in web interface'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TestWebOrders(),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Create Test Order
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.orange),
                title: const Text('Create Test Order'),
                subtitle: const Text('Create test orders via both mobile and web APIs'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateTestOrder(),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Verify Web Orders
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified, color: Colors.purple),
                title: const Text('Verify Web Orders'),
                subtitle: const Text('Test web server and verify orders are accessible'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VerifyWebOrders(),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Instructions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Use "Simple Order Test" to create a test order\n'
              '2. Check the web interface Orders tab\n'
              '3. If orders still don\'t appear, use "Order Debug Test"\n'
              '4. Check the console logs for detailed information',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
