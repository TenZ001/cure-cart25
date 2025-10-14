import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../api_service.dart';
import 'my_prescription.dart';
import 'app_bottom_nav.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  const UploadPrescriptionScreen({Key? key}) : super(key: key);

  @override
  State<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  final ApiService apiService = ApiService(); // ✅ instance created
  bool _isUploading = false;
  List<Map<String, dynamic>> _pharmacies = [];
  String? _selectedPharmacyId;
  String? _pharmacyError;
  List<String> _addresses = [];
  String? _selectedAddress;
  String? _addressError;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _gender = 'male';
  String? _paymentMethod;
  bool _cardSaved = false;
  bool _isProcessingOrder = false;
  Map<String, dynamic>? _preselectedPrescription;
  bool _isReupload = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadArguments();
  }

  void _loadArguments() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _preselectedPrescription == null) {
      _preselectedPrescription = args['preselectedPrescription'] as Map<String, dynamic>?;
      _isReupload = args['isReupload'] as bool? ?? false;
      
      if (_preselectedPrescription != null) {
        // Pre-fill form with prescription data
        _phoneController.text = _preselectedPrescription!['phone']?.toString() ?? '';
        _ageController.text = _preselectedPrescription!['age']?.toString() ?? '';
        _gender = _preselectedPrescription!['gender']?.toString() ?? 'male';
        _selectedAddress = _preselectedPrescription!['address']?.toString();
        
        // Load the prescription image if available
        if (_preselectedPrescription!['imageUrl'] != null) {
          _loadPrescriptionImage();
        }
      }
    }
  }

  Future<void> _loadPrescriptionImage() async {
    if (_preselectedPrescription?['imageUrl'] != null && _isReupload) {
      // Schedule the snack bar to show after the current frame
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Loading prescription image...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });

      try {
        final imageUrl = _preselectedPrescription!['imageUrl'] as String;
        
        // Download the image
        final response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          // Create a temporary file
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/prescription_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(response.bodyBytes);
          
          // Add the downloaded image to the images list
          if (mounted) {
            setState(() {
              _images.add(tempFile);
            });

            // Show success message after frame
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Prescription image loaded successfully! You can now upload a new image or use the existing one.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            });
          }
        } else {
          throw Exception('Failed to download image: ${response.statusCode}');
        }
      } catch (e) {
        print('Error loading prescription image: $e');
        if (mounted) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading image: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
        }
      }
    }
  }

  void _showCardDialog() {
    String cardHolderName = "";
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
              decoration: const InputDecoration(labelText: "Card Holder Name"),
              textCapitalization: TextCapitalization.words,
              onChanged: (value) => cardHolderName = value.trim(),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(labelText: "Card Number"),
              keyboardType: TextInputType.number,
              onChanged: (value) => cardNumber = value.trim(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: "MM"),
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    onChanged: (value) => expiryMonth = value.trim(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: "YYYY"),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    onChanged: (value) => expiryYear = value.trim(),
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
              onChanged: (value) => cvv = value.trim(),
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
              // Basic presence checks
              if (cardHolderName.isEmpty || cardNumber.isEmpty || cvv.isEmpty || expiryMonth.isEmpty || expiryYear.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Fill all card fields")),
                );
                return;
              }
              setState(() {
                _cardSaved = true;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<List<String>> _loadSavedAddresses() async {
    try {
      // Inline SharedPreferences access to avoid extra imports at top of file
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('user_addresses') ?? <String>[];
    } catch (_) {
      return <String>[];
    }
  }


  Future<void> _processOrder() async {
    if (_selectedPharmacyId == null || _selectedAddress == null || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _isProcessingOrder = true);

    try {
      // First upload the prescription
      final user = await apiService.getUser();
      final String? customerId = user != null ? user['id'] as String? : null;
      if (customerId == null) {
        setState(() => _isProcessingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to process orders")),
        );
        return;
      }

      // Upload prescription - this already creates the order in the backend
      bool allUploadsSuccessful = true;
      for (File image in _images) {
        final success = await apiService.uploadPrescription(
          customerId: customerId,
          image: image,
          notes: "Uploaded via app",
          pharmacyId: _selectedPharmacyId,
          customerAddress: _selectedAddress,
          customerPhone: _phoneController.text.trim(),
          customerAge: int.tryParse(_ageController.text.trim()),
          customerGender: _gender,
          paymentMethod: _paymentMethod,
        );
        if (!success) {
          allUploadsSuccessful = false;
          break;
        }
      }

      setState(() => _isProcessingOrder = false);

      if (allUploadsSuccessful) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Prescription uploaded and order created successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to orders page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MyPrescriptionScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Failed to upload prescription"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _uploadImages() async {
    if (_images.isEmpty) return;

    setState(() => _isUploading = true);

    // Read logged-in user's id from SharedPreferences
    final user = await apiService.getUser();
    final String? customerId = user != null ? user['id'] as String? : null;
    if (customerId == null) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to upload prescriptions")),
      );
      return;
    }

    bool success = false;
    for (File image in _images) {
      success = await apiService.uploadPrescription(
        customerId: customerId,
        image: image,
        notes: "Uploaded via app",
      );
      if (!success) break; // stop on first failure
    }

    setState(() {
      _isUploading = false;
      _images.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? "✅ Uploaded successfully!" : "❌ Upload failed!",
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyPrescriptionScreen()),
      );
    }
  }

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
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(152, 223, 223, 223),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      "Upload Prescription",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Pharmacy selection (approved only from web)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: apiService.getApprovedPharmacies(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: LinearProgressIndicator(minHeight: 2),
                        );
                      }
                      if (snapshot.hasError) {
                        print('❌ Pharmacy loading error: ${snapshot.error}');
                        return Text(
                          "Error loading pharmacies: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      _pharmacies = snapshot.data ?? [];
                      print('📱 Loaded ${_pharmacies.length} pharmacies');
                      if (_pharmacies.isEmpty) {
                        return const Text(
                          "No approved pharmacies available yet.",
                          style: TextStyle(color: Colors.black54),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Select a Pharmacy",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedPharmacyId,
                            items: _pharmacies
                                .map((p) => DropdownMenuItem<String>(
                                      value: p['_id'].toString(),
                                      child: Text(
                                        '${p['name']} — ${p['contact'] ?? ''}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedPharmacyId = val;
                                _pharmacyError = null;
                              });
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              // errorText set dynamically below
                            ).copyWith(
                              errorText: _pharmacyError,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Address selection (from saved addresses)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FutureBuilder<List<String>>(
                    future: _loadSavedAddresses(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: LinearProgressIndicator(minHeight: 2),
                        );
                      }
                      _addresses = snapshot.data ?? [];
                      if (_addresses.isEmpty) {
                        return const Text(
                          "No saved addresses. Add one in My Addresses.",
                          style: TextStyle(color: Colors.black54),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Select a Delivery Address",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedAddress,
                            items: _addresses
                                .map((a) => DropdownMenuItem<String>(
                                      value: a,
                                      child: Text(a, overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedAddress = val;
                                _addressError = null;
                              });
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ).copyWith(
                              errorText: _addressError,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                Image.asset("assets/icons/upload_pres.png", height: 270),

                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Upload your prescription",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Upload your prescription issued by your doctor. "
                  "Make sure the image is clear and includes all details.",
                  textAlign: TextAlign.left,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),

                const SizedBox(height: 20),

                // Contact number input (required)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Contact Number",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: const InputDecoration(
                          hintText: 'Enter a phone number for contact',
                          border: OutlineInputBorder(),
                          isDense: true,
                          counterText: '', // Hide the character counter
                        ),
                        onChanged: (value) {
                          // Only allow digits and limit to 10 characters
                          if (value.length > 10) {
                            _phoneController.text = value.substring(0, 10);
                            _phoneController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _phoneController.text.length),
                            );
                          }
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Age and Gender (same line)
                Row(
                  children: [
                    // Age input
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Age",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                            decoration: const InputDecoration(
                              hintText: 'Enter age',
                              border: OutlineInputBorder(),
                              isDense: true,
                              counterText: '', // Hide the character counter
                            ),
                            onChanged: (value) {
                              // Only allow digits and limit to below 120
                              if (value.isNotEmpty) {
                                final age = int.tryParse(value);
                                if (age != null && age >= 120) {
                                  _ageController.text = '119';
                                  _ageController.selection = TextSelection.fromPosition(
                                    TextPosition(offset: _ageController.text.length),
                                  );
                                }
                              }
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Gender radio
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Gender",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Male'),
                                  value: 'male',
                                  groupValue: _gender,
                                  onChanged: (val) => setState(() => _gender = val ?? 'male'),
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Female'),
                                  value: 'female',
                                  groupValue: _gender,
                                  onChanged: (val) => setState(() => _gender = val ?? 'female'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),


                const SizedBox(height: 16),

                // Payment method (reuse checkout pattern)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Select Payment Method:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                RadioListTile<String>(
                  title: const Text("Credit/Debit Card"),
                  value: "card",
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value;
                      _cardSaved = false; // require fresh details if re-selected
                    });
                    _showCardDialog();
                  },
                ),
                RadioListTile<String>(
                  title: const Text("Cash on Delivery"),
                  value: "cod",
                  groupValue: _paymentMethod,
                  onChanged: (value) => setState(() => _paymentMethod = value),
                ),

                SizedBox(
                  width: 350,
                  child: OutlinedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                    child: const Text(
                      "Take Picture",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: 350,
                  child: OutlinedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                    child: const Text(
                      "Upload from Gallery",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Column(
                  children: List.generate(_images.length, (index) {
                    return ListTile(
                      leading: const Icon(Icons.image, color: Colors.black54),
                      title: Text(
                        _images[index].path.split('/').last,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.black54),
                        onPressed: () => _removeImage(index),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _images.isNotEmpty && !_isProcessingOrder
                        ? () async {
                            // Require pharmacy selection
                            if (_selectedPharmacyId == null || _selectedPharmacyId!.isEmpty) {
                              setState(() {
                                _pharmacyError = 'Select a pharmacy';
                              });
                              return;
                            }
                            // Require address selection
                            if (_selectedAddress == null || _selectedAddress!.isEmpty) {
                              setState(() {
                                _addressError = 'Select a delivery address';
                              });
                              return;
                            }
                            // Require phone number
                            final phone = _phoneController.text.trim();
                            if (phone.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Enter a contact number")),
                              );
                              return;
                            }
                            // Require payment method
                            if (_paymentMethod == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Select a payment method")),
                              );
                              return;
                            }
                            if (_paymentMethod == 'card' && !_cardSaved) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Enter card details")),
                              );
                              return;
                            }
                            // Process the order
                            await _processOrder();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isProcessingOrder
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Upload & Create Order",
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
