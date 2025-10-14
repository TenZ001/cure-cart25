import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'api_service.dart';

class SavedPrescriptionScreen extends StatefulWidget {
  const SavedPrescriptionScreen({Key? key}) : super(key: key);

  @override
  State<SavedPrescriptionScreen> createState() => _SavedPrescriptionScreenState();
}

class _SavedPrescriptionScreenState extends State<SavedPrescriptionScreen> {
  List<Map<String, dynamic>> _saved = [];
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList('saved_prescriptions') ?? [];
    setState(() {
      _saved = raw.map<Map<String, dynamic>>((s) {
        try {
          return Map<String, dynamic>.from(jsonDecode(s));
        } catch (_) {
          return {};
        }
      }).where((m) => m.isNotEmpty).toList();
    });
  }

  void _showDetails(Map<String, dynamic> p) {
    final date = (p['date'] ?? '').toString();
    final status = (p['status'] ?? 'Submitted').toString();
    final name = (p['name'] ?? 'Prescription').toString();
    final ocr = (p['ocrData'] ?? '').toString();
    final imageUrl = p['imageUrl']?.toString();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("📅 Date: $date\nStatus: $status${ocr.isNotEmpty ? "\nNotes: $ocr" : ""}"),
              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text("Prescription Image:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _viewImage(imageUrl),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error, size: 48, color: Colors.red),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Tap image to view full size", 
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Close')
          ),
          if (imageUrl != null && imageUrl.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _reuploadPrescription(p);
              },
              child: const Text('Re-upload'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(p);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Prescription Image'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
              ),
            ],
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Failed to load image', 
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => Navigator.pop(context),
            backgroundColor: Colors.black54,
            foregroundColor: Colors.white,
            child: const Icon(Icons.close),
            tooltip: 'Close image',
          ),
        ),
      ),
    );
  }

  void _reuploadPrescription(Map<String, dynamic> prescription) {
    // Navigate to upload prescription page with pre-selected prescription
    Navigator.pushNamed(
      context,
      '/upload',
      arguments: {
        'preselectedPrescription': prescription,
        'isReupload': true,
      },
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> prescription) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Prescription'),
          content: Text('Are you sure you want to delete "${prescription['name'] ?? 'this prescription'}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deletePrescription(prescription);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePrescription(Map<String, dynamic> prescription) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> raw = prefs.getStringList('saved_prescriptions') ?? [];
      
      // Remove the prescription from the list
      final updatedList = raw.where((item) {
        try {
          final Map<String, dynamic> parsed = Map<String, dynamic>.from(jsonDecode(item));
          return parsed['name'] != prescription['name'] || 
                 parsed['date'] != prescription['date'] ||
                 parsed['imageUrl'] != prescription['imageUrl'];
        } catch (_) {
          return true; // Keep items that can't be parsed
        }
      }).toList();
      
      await prefs.setStringList('saved_prescriptions', updatedList);
      
      // Reload the saved prescriptions
      await _loadSaved();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete prescription: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Saved Prescriptions"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _saved.isEmpty
            ? const Center(child: Text('No saved prescriptions'))
            : ListView.builder(
                itemCount: _saved.length,
                itemBuilder: (context, index) {
                  final p = _saved[index];
                  return Card(
                    child: ListTile(
                      leading: (p['imageUrl'] != null && (p['imageUrl'] as String).toString().isNotEmpty)
                          ? GestureDetector(
                              onTap: () => _viewImage(p['imageUrl']),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  p['imageUrl'], 
                                  width: 60, 
                                  height: 60, 
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.error, color: Colors.red),
                                    );
                                  },
                                ),
                              ),
                            )
                          : const Icon(Icons.receipt_long, size: 36),
                      title: Text(p['name'] ?? 'Prescription'),
                      subtitle: Text('Date: ${p['date'] ?? ''} • Status: ${p['status'] ?? 'Submitted'}'),
                      onTap: () => _showDetails(p),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (p['imageUrl'] != null && (p['imageUrl'] as String).toString().isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.upload, color: Colors.blue),
                              onPressed: () => _reuploadPrescription(p),
                              tooltip: 'Re-upload prescription',
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _showDeleteConfirmation(p),
                            tooltip: 'Delete prescription',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
