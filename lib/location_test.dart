import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationTestScreen extends StatefulWidget {
  const LocationTestScreen({super.key});

  @override
  State<LocationTestScreen> createState() => _LocationTestScreenState();
}

class _LocationTestScreenState extends State<LocationTestScreen> {
  String _status = "Testing location services...";
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _testLocationServices();
  }

  Future<void> _testLocationServices() async {
    try {
      setState(() {
        _status = "Checking location services...";
      });

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _status = "Location services are disabled";
        });
        return;
      }

      setState(() {
        _status = "Checking permissions...";
      });

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _status = "Location permissions denied";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _status = "Location permissions permanently denied";
        });
        return;
      }

      setState(() {
        _status = "Getting current location...";
      });

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _status = "Location services working!";
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      setState(() {
        _status = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location Test"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Location Services Test",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("Status: $_status"),
                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 8),
                      Text("Latitude: $_latitude"),
                      Text("Longitude: $_longitude"),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Troubleshooting Steps:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text("1. Make sure location services are enabled on your device"),
                    Text("2. Grant location permissions to the app"),
                    Text("3. Try running the app on a physical device (not emulator)"),
                    Text("4. Check that the geolocator plugin is properly installed"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testLocationServices,
                child: const Text("Test Again"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
