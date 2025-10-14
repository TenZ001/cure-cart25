// file: lib/med_scan.dart
import 'package:cure_cart_mobile/medicine_details.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_bottom_nav.dart';
import 'dart:io';

class MedScanPage extends StatefulWidget {
  const MedScanPage({super.key});

  @override
  State<MedScanPage> createState() => _MedScanPageState();
}

class _MedScanPageState extends State<MedScanPage> {
  final ImagePicker _picker = ImagePicker();
  File? _image;

  // track selected button to change color
  int selectedButton = -1;

  Future<void> _openCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _openGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black87,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            // Simple pop navigation - let Flutter handle it
            Navigator.pop(context);
          },
          style: IconButton.styleFrom(
            foregroundColor: Colors.black87,
            backgroundColor: Colors.transparent,
          ),
        ),
        title: const Text(
          "MED SCAN",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F9FA), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Simple camera viewfinder
            Expanded(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Camera preview or image
                      if (_image != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _image!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      
                      // Simple instructions
                      if (_image == null)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Align Medicine in Frame",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Position medicine label clearly",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Simple medicine details button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _image == null 
                        ? Colors.grey.shade300 
                        : Colors.blue.shade600,
                    foregroundColor: _image == null 
                        ? Colors.grey.shade600 
                        : Colors.white,
                    elevation: _image == null ? 0 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _image == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MedicineDetailsPage(imageFile: _image!),
                            ),
                          );
                        },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_information_outlined,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Check Medicine Details",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Simple bottom buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery button
                  _buildSimpleButton(
                    index: 0,
                    icon: Icons.photo_library_outlined,
                    onTap: _openGallery,
                  ),
                  // Camera button (primary) - elevated
                  Transform.translate(
                    offset: const Offset(0, -5),
                    child: _buildSimpleButton(
                      index: 1,
                      icon: Icons.camera_alt_outlined,
                      onTap: _openCamera,
                      isPrimary: true,
                    ),
                  ),
                  // Scan button
                  _buildSimpleButton(
                    index: 2,
                    icon: Icons.qr_code_scanner_outlined,
                    onTap: _openGallery,
                  ),
                ],
              ),
            ),
        ],
      ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
  );
  }

  // 🔹 Enhanced button widget with colors and hover effects
  Widget _buildSimpleButton({
    required int index,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    bool isSelected = selectedButton == index;

    // Different colors for each button
    Color getButtonColor() {
      if (isSelected) {
        switch (index) {
          case 0: return Colors.orange.shade100; // Gallery - Orange
          case 1: return Colors.blue.shade100;   // Camera - Blue
          case 2: return Colors.purple.shade100; // Scan - Purple
          default: return Colors.blue.shade100;
        }
      } else {
        return Colors.grey.shade200;
      }
    }

    Color getBorderColor() {
      if (isSelected) {
        switch (index) {
          case 0: return Colors.orange.shade400; // Gallery - Orange
          case 1: return Colors.blue.shade400;  // Camera - Blue
          case 2: return Colors.purple.shade400; // Scan - Purple
          default: return Colors.blue.shade400;
        }
      } else {
        return Colors.grey.shade300;
      }
    }

    Color getIconColor() {
      if (isSelected) {
        switch (index) {
          case 0: return Colors.orange.shade700; // Gallery - Orange
          case 1: return Colors.blue.shade700;  // Camera - Blue
          case 2: return Colors.purple.shade700; // Scan - Purple
          default: return Colors.blue.shade700;
        }
      } else {
        return Colors.grey.shade600;
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedButton = index;
        });
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isPrimary ? 85 : 65,
        height: isPrimary ? 85 : 65,
        decoration: BoxDecoration(
          color: getButtonColor(),
          shape: BoxShape.circle,
          border: Border.all(
            color: getBorderColor(),
            width: isPrimary ? 3 : 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: getBorderColor().withOpacity(0.3),
                blurRadius: isPrimary ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(isPrimary ? 42.5 : 32.5),
            onTap: () {
              setState(() {
                selectedButton = index;
              });
              onTap();
            },
            child: Icon(
              icon,
              color: getIconColor(),
              size: isPrimary ? 32 : 26,
            ),
          ),
        ),
      ),
    );
  }
}
