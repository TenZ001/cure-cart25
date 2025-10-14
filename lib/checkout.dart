// file: lib/checkout.dart
import 'package:flutter/material.dart';
import 'my_orders.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'dart:convert';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const CheckoutPage({Key? key, required this.items}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? selectedPayment;
  String? selectedAddress;
  List<String> userAddresses = [];
  List<Map<String, dynamic>> approvedPharmacies = [];
  String? selectedPharmacyId;
  bool _loadingPharmacies = false;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserAddresses();
    _loadApprovedPharmacies();
  }

  Future<void> _loadUserAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('user_addresses') ?? [];
    setState(() {
      userAddresses = saved;
      if (userAddresses.isNotEmpty) {
        selectedAddress = userAddresses.first;
      } else {
        selectedAddress = null;
      }
    });
  }

  Future<void> _loadApprovedPharmacies() async {
    setState(() => _loadingPharmacies = true);
    try {
      print('🔍 Loading approved pharmacies in checkout...');
      final pharmacies = await apiService.getApprovedPharmacies();
      print('📊 Checkout received ${pharmacies.length} pharmacies');
      print('📋 Checkout pharmacy data: $pharmacies');
      
      if (mounted) {
        setState(() {
          approvedPharmacies = pharmacies;
          _loadingPharmacies = false;
          if (pharmacies.isNotEmpty) {
            selectedPharmacyId = pharmacies.first['_id'].toString();
            print('✅ Selected pharmacy ID: $selectedPharmacyId');
          }
        });
        print('✅ Updated checkout UI with ${approvedPharmacies.length} pharmacies');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingPharmacies = false);
      }
      print('❌ Error loading pharmacies in checkout: $e');
    }
  }


  Future<void> _saveOrderLocally(Map<String, dynamic> orderResult, Map<String, dynamic> selectedPharmacy, int total, [String? overrideId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> savedOrders = prefs.getStringList('user_orders') ?? [];
      
      final dynamic providedId = overrideId ?? orderResult["_id"] ?? orderResult["id"] ?? orderResult["orderId"];
      final String localId = (providedId == null || providedId.toString().isEmpty)
          ? "local_${DateTime.now().millisecondsSinceEpoch}"
          : providedId.toString();

      final orderData = {
        "_id": localId, // Ensure non-empty id
        "id": localId, // Keep both for compatibility
        "name": widget.items.first["name"],
        "price": widget.items.first["price"],
        "qty": widget.items.first["qty"],
        "pharmacy": selectedPharmacy['name'] ?? 'Unknown Pharmacy',
        "pharmacyId": selectedPharmacy['_id'],
        "total": total,
        "status": "pending", // This will make it appear in purchased tab
        "createdAt": DateTime.now().toIso8601String(),
        "items": widget.items.map((item) => {
          "name": item["name"],
          "quantity": item["qty"] ?? 1,
          "price": item["price"],
        }).toList(),
        "address": selectedAddress,
        "paymentMethod": selectedPayment,
      };
      
      savedOrders.add(jsonEncode(orderData));
      await prefs.setStringList('user_orders', savedOrders);
      
      print('✅ Order saved locally with ID: ${orderData["id"]}');
      print('✅ Order status: ${orderData["status"]}');
      print('✅ Order total: ${orderData["total"]}');
      print('✅ Order items: ${orderData["items"]}');
      print('✅ Order will be visible to pharmacist in web interface');
    } catch (e) {
      print('❌ Error saving order locally: $e');
    }
  }

  void _showCardDialog() {
    String cardNumber = "";
    String expiryMonth = "";
    String expiryYear = "";
    String cvv = "";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Credit Card"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Card Number"),
              keyboardType: TextInputType.number,
              onChanged: (value) => cardNumber = value,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: "MM"),
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    onChanged: (value) => expiryMonth = value,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: "YYYY"),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    onChanged: (value) => expiryYear = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(labelText: "CVV"),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 3,
              onChanged: (value) => cvv = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Card $cardNumber saved!")),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int subTotal = widget.items.fold<int>(
      0,
      (sum, item) => sum + (item['price'] as int) * (item['qty'] as int),
    );
    const int deliveryCharges = 150;
    int total = subTotal + deliveryCharges;

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Pharmacy selection card
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.local_pharmacy,
                  size: 40,
                  color: Colors.black54,
                ),
                title: _loadingPharmacies
                    ? const Text("Loading pharmacies...")
                    : approvedPharmacies.isEmpty
                        ? Text("No approved pharmacies available (${approvedPharmacies.length})")
                        : DropdownButton<String>(
                            value: selectedPharmacyId,
                            underline: const SizedBox(),
                            items: approvedPharmacies.map((pharmacy) {
                              return DropdownMenuItem(
                                value: pharmacy['_id'].toString(),
                                child: Text(pharmacy['name'] ?? 'Unknown Pharmacy'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => selectedPharmacyId = value!);
                            },
                          ),
                subtitle: const Text("Select your preferred pharmacy"),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Medicines list
            Expanded(
              child: ListView.builder(
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.medication, size: 40),
                      title: Text(item['name']),
                      subtitle: Text("Rs. ${item['price']} x${item['qty']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => widget.items.removeAt(index));
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // ✅ Charges
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Sub Total: Rs.$subTotal"),
                    Text("Delivery Charges: Rs.$deliveryCharges"),
                    Text(
                      "Total: Rs.$total",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ Address (only user-added)
            DropdownButtonFormField<String>(
              initialValue: selectedAddress,
              decoration: const InputDecoration(
                labelText: "Delivery Address",
                border: OutlineInputBorder(),
              ),
              items: userAddresses
                  .map((address) => DropdownMenuItem(
                        value: address,
                        child: Text(address),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => selectedAddress = value);
              },
            ),
            if (userAddresses.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No saved addresses. Add one from Menu > My Addresses',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: 16),

            // ✅ Payment
            const Text(
              "Select Payment Method:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            RadioListTile<String>(
              title: const Text("Credit/Debit Card"),
              value: "card",
              groupValue: selectedPayment,
              onChanged: (value) {
                setState(() => selectedPayment = value);
                _showCardDialog();
              },
            ),
            RadioListTile<String>(
              title: const Text("Cash on Delivery"),
              value: "cod",
              groupValue: selectedPayment,
              onChanged: (value) => setState(() => selectedPayment = value),
            ),
            const SizedBox(height: 12),

            // ✅ Proceed to Pay
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: selectedPayment == null || selectedPharmacyId == null || selectedAddress == null
                    ? null
                    : () async {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        try {
                          final selectedPharmacy = approvedPharmacies.firstWhere(
                            (pharmacy) => pharmacy['_id'].toString() == selectedPharmacyId,
                            orElse: () => approvedPharmacies.first,
                          );

                          // Create order via API
                          final orderResult = await apiService.createOrder(
                            items: widget.items,
                            pharmacyId: selectedPharmacyId!,
                            address: selectedAddress!,
                            paymentMethod: selectedPayment!,
                            total: total,
                            pharmacyName: (selectedPharmacy['name'] ?? '').toString(),
                            pharmacyAddress: (selectedPharmacy['address'] ?? '').toString(),
                          );

                          // Close loading dialog
                          Navigator.pop(context);

                          if (orderResult != null) {
                            final String safeOrderId = (
                              orderResult["_id"] ?? orderResult["id"] ?? orderResult["orderId"] ?? "local_${DateTime.now().millisecondsSinceEpoch}"
                            ).toString();
                            // Show success message with order details
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Order placed successfully! Order ID: $safeOrderId"),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 4),
                              ),
                            );

                            // Store order in local storage for persistence
                            await _saveOrderLocally(orderResult, selectedPharmacy, total, safeOrderId);

                            // Navigate to working orders page with a small delay to ensure data is saved
                            await Future.delayed(const Duration(milliseconds: 500));
                            
                            // Navigate to My Orders page
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyOrdersPage(purchasedOrders: [], pendingOrders: []),
                              ),
                            );
                          } else {
                            // Show error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to place order. Please try again."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          // Close loading dialog
                          Navigator.pop(context);
                          
                          // Show error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: const Text(
                  "Proceed to Pay",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
