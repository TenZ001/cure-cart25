// file: lib/medicine_details.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

import 'med_scan.dart'; // back navigation

class MedicineDetailsPage extends StatefulWidget {
  final File imageFile; // image passed from MedScanPage

  const MedicineDetailsPage({super.key, required this.imageFile});

  @override
  State<MedicineDetailsPage> createState() => _MedicineDetailsPageState();
}

class _MedicineDetailsPageState extends State<MedicineDetailsPage> {
  String ocrText = "Processing...";
  Map<String, dynamic>? medicineInfo;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  // 🔹 OCR + API call
  Future<void> _processImage() async {
    try {
      // OCR
      final textRecognizer = TextRecognizer();
      final inputImage = InputImage.fromFile(widget.imageFile);
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      textRecognizer.close();

      setState(() {
        ocrText = recognizedText.text;
      });

      // Take first word/line → use as candidate
      String medicineCandidate = recognizedText.text.split("\n").first;

      // Map brand → generic if needed
      String query = _mapBrandToGeneric(medicineCandidate);

      // Fetch details from OpenFDA
      await _fetchMedicineDetails(query);
    } catch (e) {
      setState(() {
        ocrText = "Error: $e";
      });
    }
  }

  // 🔹 Map brand names → generic names for API
  String _mapBrandToGeneric(String brand) {
    brand = brand.toLowerCase();
    if (brand.contains("amcard")) return "amlodipine";
    if (brand.contains("paracetamol")) return "paracetamol";
    if (brand.contains("naproxen")) return "naproxen";
    return brand.split(" ").first; // fallback
  }

  // 🔹 API Call
  Future<void> _fetchMedicineDetails(String query) async {
    try {
      final url = Uri.parse(
        "https://api.fda.gov/drug/label.json?search=openfda.generic_name:$query&limit=1",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["results"] != null && data["results"].isNotEmpty) {
          setState(() {
            medicineInfo = data["results"][0];
          });
        } else {
          setState(() {
            ocrText = "No details found for $query.";
          });
        }
      } else {
        setState(() {
          ocrText = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        ocrText = "Error fetching details: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MedScanPage()),
            );
          },
        ),
        title: const Text("Medicine Details"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Show scanned image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                widget.imageFile,
                height: 160,
                width: 260,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 16),

            // Medicine Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: medicineInfo != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Medications",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Medicine Name: ${medicineInfo?["openfda"]?["brand_name"]?.join(", ") ?? "Not found"}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Dosage: ${medicineInfo?["dosage_and_administration"]?[0] ?? "As directed by physician"}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Storage: ${medicineInfo?["storage_and_handling"]?[0] ?? "Store below 30°C"}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Intended Use: ${medicineInfo?["indications_and_usage"]?[0] ?? "No data available"}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Text(
                          "Fetching details...",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          ocrText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
