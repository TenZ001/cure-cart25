// file: lib/fever_med_buy.dart
import 'package:flutter/material.dart';
import 'my_orders.dart'; // ✅ import orders page

class FeverMedBuyPage extends StatelessWidget {
  const FeverMedBuyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final medicine = {
      "name": "Naproxen",
      "price": 299,
      "qty": 1,
      "pharmacy": "R Pharmacy - Kurunegala",
    };

    return Scaffold(
      appBar: AppBar(title: const Text("Fever Medicine")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/icons/product1.png", height: 160),
                  const SizedBox(height: 12),
                  const Text(
                    "Naproxen",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Rs.299",
                    style: TextStyle(fontSize: 18, color: Colors.green),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Naproxen is used to relieve pain, swelling, stiffness "
                    "caused by conditions such as arthritis, muscle aches, "
                    "backaches, menstrual cramps, and other minor pain.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),

          // ✅ Only one Buy Now button at the bottom
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: () {
                // Add medicine into Pending Orders
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyOrdersPage(
                      purchasedOrders: [],
                      pendingOrders: [medicine],
                    ),
                  ),
                );
              },
              child: const Text(
                "Buy Now",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
