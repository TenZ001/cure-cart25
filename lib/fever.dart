import 'package:flutter/material.dart';
// Import HomeScreen for navigation
import 'fever_med_buy.dart'; // Import FeverMedBuyScreen for navigation

class FeverScreen extends StatelessWidget {
  const FeverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Quick Care'),
      ),
      body: Container(
        color: const Color.fromARGB(139, 225, 245, 254),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                color: const Color.fromARGB(169, 196, 196, 196),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fever',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Image.asset(
                      'assets/icons/fever_icon.png', // Fever icon as per your asset
                      height: 80,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(16.0),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildMedicineCard(
                      context,
                      'Paracetamol',
                      'assets/icons/product4.png',
                      () {
                        // Handle Paracetamol click
                      },
                    ),
                    _buildMedicineCard(
                      context,
                      'Ibuprofen',
                      'assets/icons/product3.png',
                      () {
                        // Handle Ibuprofen click
                      },
                    ),
                    _buildMedicineCard(
                      context,

                      'Naproxen',
                      'assets/icons/product1.png',
                      () {
                        // Navigate to FeverMedBuyScreen for Aspirin
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FeverMedBuyPage(),
                          ),
                        );
                      },
                    ),
                    _buildMedicineCard(
                      context,
                      'Aspirin',
                      'assets/icons/product2.png',
                      () {
                        // Handle Naproxen click
                      },
                    ),
                    _buildMedicineCard(
                      context,
                      'Paracetamol',
                      'assets/icons/product4.png',
                      () {
                        // Handle additional Paracetamol click
                      },
                    ),
                    _buildMedicineCard(
                      context,
                      'Ibuprofen',
                      'assets/icons/product3.png',
                      () {
                        // Handle additional Ibuprofen click
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 0,
        onTap: (index) {},
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildMedicineCard(
    BuildContext context,
    String title,
    String imagePath,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 100, fit: BoxFit.contain),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
