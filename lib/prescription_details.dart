import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_bottom_nav.dart';

class PrescriptionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> prescription;
  final String? prescriptionId; // Optional parameter for ID
  final String? date; // Optional parameter for date

  const PrescriptionDetailsScreen({
    Key? key,
    required this.prescription,
    this.prescriptionId,
    this.date,
  }) : super(key: key);

  @override
  State<PrescriptionDetailsScreen> createState() =>
      _PrescriptionDetailsScreenState();
}

class _PrescriptionDetailsScreenState extends State<PrescriptionDetailsScreen> {
  String _detailedInfo = 'Loading...';
  double _imageHeight = 300.0;
  double _imageWidth = 200.0;
  double _statusContainerHeight = 40.0;
  double _statusContainerWidth = 150.0;
  double _cardHeight = 300.0;
  double _cardWidth = 300.0;

  @override
  void initState() {
    super.initState();
    _fetchDrugDetails();
  }

  Future<void> _fetchDrugDetails() async {
    String medication = widget.prescription['ocrData'].contains('Augmentin')
        ? 'Augmentin'
        : 'Unknown';
    final response = await http.get(
      Uri.parse('https://api.drugbank.com/v1/drugs?name=$medication'),
    );
    if (response.statusCode == 200) {
      setState(() {
        _detailedInfo = 'Details for $medication: ${response.body}';
      });
    } else {
      setState(() {
        _detailedInfo = 'Failed to fetch details';
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Declined':
        return Colors.red;
      case 'Submitted':
        return Colors.yellow;
      default:
        return Colors.grey;
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
        title: const Text('Prescription Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onScaleUpdate: (details) {
                  setState(() {
                    _imageHeight = (_imageHeight * details.scale).clamp(
                      100.0,
                      400.0,
                    );
                    _imageWidth = (_imageWidth * details.scale).clamp(
                      100.0,
                      400.0,
                    );
                  });
                },
                child: (widget.prescription['imageUrl'] != null &&
                        (widget.prescription['imageUrl'] as String)
                            .toString()
                            .isNotEmpty)
                    ? Image.network(
                        widget.prescription['imageUrl'],
                        height: _imageHeight,
                        width: _imageWidth,
                        fit: BoxFit.contain,
                      )
                    : Image.asset(
                        'assets/icons/prescription_image.png',
                        height: _imageHeight,
                        width: _imageWidth,
                        fit: BoxFit.contain,
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Order status', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onScaleUpdate: (details) {
                      setState(() {
                        _statusContainerHeight =
                            (_statusContainerHeight * details.scale).clamp(
                              30.0,
                              100.0,
                            );
                        _statusContainerWidth =
                            (_statusContainerWidth * details.scale).clamp(
                              100.0,
                              300.0,
                            );
                      });
                    },
                    child: Container(
                      height: _statusContainerHeight,
                      width: _statusContainerWidth,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.prescription['status']),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          widget.prescription['status'] ?? 'Approved',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onScaleUpdate: (details) {
                  setState(() {
                    _cardHeight = (_cardHeight * details.scale).clamp(
                      200.0,
                      500.0,
                    );
                    _cardWidth = (_cardWidth * details.scale).clamp(
                      200.0,
                      400.0,
                    );
                  });
                },
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SizedBox(
                    height: _cardHeight,
                    width: _cardWidth,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Medications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign
                                .center, // Changed to center for consistency
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.prescription['ocrData'] ?? 'No OCR data',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Additional Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign
                                .center, // Changed to center for consistency
                          ),
                          const SizedBox(height: 10),
                          Text(_detailedInfo, textAlign: TextAlign.center),
                          if (widget.prescriptionId != null &&
                              widget.date != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Prescription ID: ${widget.prescriptionId}',
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Date: ${widget.date}',
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}
