import 'package:flutter/material.dart';

class DrugDetailsPage extends StatelessWidget {
  final Map<String, dynamic> medicine;

  const DrugDetailsPage({Key? key, required this.medicine}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(medicine['name'] ?? "Medicine")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (medicine['image'] != null &&
                medicine['image'].toString().isNotEmpty)
              Center(
                child: Image.network(
                  medicine['image'],
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 20),
            Text(
              medicine['name'] ?? "Unknown",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Rs. ${medicine['price']?.toString() ?? 'N/A'}",
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              medicine['description'] ?? "No description available.",
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(140, 48)),
                  onPressed: () {
                    // TODO: Add to Cart logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Added to Cart 🛒")),
                    );
                  },
                  child: const Text("Add to Cart"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(140, 48)),
                  onPressed: () {
                    // TODO: Buy Now logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Proceed to Buy ✅")),
                    );
                  },
                  child: const Text("Buy Now"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
