import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyAddressPage extends StatefulWidget {
  const MyAddressPage({Key? key}) : super(key: key);

  @override
  State<MyAddressPage> createState() => _MyAddressPageState();
}

class _MyAddressPageState extends State<MyAddressPage> {
  final TextEditingController _addressController = TextEditingController();
  List<String> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _addresses = prefs.getStringList('user_addresses') ?? [];
    });
  }

  Future<void> _saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('user_addresses', _addresses);
  }

  Future<void> _addAddress() async {
    final text = _addressController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _addresses.add(text);
      _addressController.clear();
    });
    await _saveAddresses();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address added')),
    );
  }

  Future<void> _deleteAddress(int index) async {
    setState(() {
      _addresses.removeAt(index);
    });
    await _saveAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Addresses'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a new address',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      hintText: 'Enter address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addAddress,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Saved addresses',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _addresses.isEmpty
                  ? const Center(child: Text('No addresses added yet'))
                  : ListView.builder(
                      itemCount: _addresses.length,
                      itemBuilder: (context, index) {
                        final address = _addresses[index];
                        return Card(
                          child: ListTile(
                            title: Text(address),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAddress(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


