# 🗺️ Live Location Tracking System

A comprehensive location tracking system for CureCart mobile app with modern UI and real-time updates using OpenStreetMap API.

## ✨ Features

### 📱 Customer App Features
- **Track Order Button**: Appears when prescription status is "Dispatched"
- **Live Location Updates**: Real-time tracking of delivery partner location
- **Modern UI**: Beautiful, responsive design with gradient backgrounds
- **Progress Tracking**: Visual progress steps for order status
- **Distance & ETA**: Real-time distance and estimated delivery time

### 🚚 Delivery Partner App Features
- **Location Tracking Screen**: Dedicated screen for delivery partners
- **Customer Information**: Display customer details and contact info
- **Live Location Sharing**: Automatic location updates every 5 seconds
- **Distance Calculation**: Real-time distance to customer location
- **Start/Stop Tracking**: Manual control over location sharing

## 🏗️ Architecture

### Files Structure
```
lib/
├── my_prescription.dart              # Updated with track order button
├── track_order.dart                  # Enhanced customer tracking screen
└── delivery/
    ├── location_tracking_screen.dart # New delivery partner tracking
    └── orders_screen.dart           # Updated with track button
```

### Dependencies Added
```yaml
dependencies:
  geolocator: ^10.1.0        # Location services
  flutter_map: ^6.1.0        # OpenStreetMap integration
  latlong2: ^0.9.1           # Geographic coordinates
```

## 🎨 UI Components

### Customer Tracking Screen (`track_order.dart`)
- **Map Section**: OpenStreetMap with custom markers
- **Status Card**: Delivery partner info and order status
- **Progress Steps**: Visual order progress indicator
- **Info Cards**: Distance, ETA, and contact information

### Delivery Partner Screen (`location_tracking_screen.dart`)
- **Map Section**: Real-time location display
- **Customer Info**: Name, phone, and address
- **Tracking Controls**: Start/stop location sharing
- **Status Indicators**: Distance, ETA, and tracking status

## 🔧 Implementation Details

### Location Services
```dart
// Get current location
final position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
);

// Update delivery location
await apiService.updateDeliveryLocation(
  orderId,
  position.latitude,
  position.longitude,
);
```

### Map Integration
```dart
// OpenStreetMap tiles
TileLayer(
  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
  subdomains: const ['a', 'b', 'c'],
)

// Custom markers
Marker(
  point: LatLng(lat, lng),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.blue,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(...)],
    ),
    child: Icon(Icons.home),
  ),
)
```

### Real-time Updates
```dart
// Location tracking timer
_locationTimer = Timer.periodic(
  const Duration(seconds: 5),
  (timer) => _updateLocation(),
);
```

## 🚀 Usage

### For Customers
1. Navigate to "My Prescriptions"
2. Find prescription with "Dispatched" status
3. Click "Track Order" button
4. View real-time delivery partner location
5. Monitor order progress and ETA

### For Delivery Partners
1. Go to "Orders" screen
2. Find assigned order
3. Click "Track" button
4. View customer information
5. Start location tracking
6. Monitor distance and ETA

## 🎯 Key Features

### Modern UI Design
- **Gradient Backgrounds**: Beautiful color gradients
- **Card-based Layout**: Clean, organized information display
- **Custom Markers**: Distinctive location markers
- **Responsive Design**: Adapts to different screen sizes

### Real-time Functionality
- **Live Location Updates**: 5-second intervals
- **Distance Calculation**: Real-time distance measurement
- **ETA Calculation**: Estimated time of arrival
- **Status Tracking**: Order progress monitoring

### OpenStreetMap Integration
- **Free Map Tiles**: No API key required
- **High Performance**: Fast map rendering
- **Custom Styling**: Beautiful map appearance
- **Offline Support**: Cached map tiles

## 🔒 Privacy & Security

### Location Permissions
- **High Accuracy**: Precise location tracking
- **User Consent**: Permission-based location access
- **Data Protection**: Secure location data handling

### API Security
- **Authenticated Requests**: Secure API calls
- **Data Validation**: Input validation and sanitization
- **Error Handling**: Graceful error management

## 📱 Platform Support

### Android
- **Location Services**: GPS and network location
- **Background Updates**: Continuous location tracking
- **Permission Handling**: Runtime permission requests

### iOS
- **Core Location**: Native iOS location services
- **Privacy Compliance**: iOS privacy guidelines
- **Background Modes**: Location updates in background

## 🛠️ Setup Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to track deliveries</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to track deliveries</string>
```

### 3. Run the App
```bash
flutter run
```

## 🎨 Customization

### Map Styling
```dart
// Custom map tiles
TileLayer(
  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
  subdomains: const ['a', 'b', 'c'],
  userAgentPackageName: 'com.curecart.app',
)
```

### Marker Customization
```dart
// Custom marker styling
Container(
  decoration: BoxDecoration(
    color: Colors.blue,
    shape: BoxShape.circle,
    border: Border.all(color: Colors.white, width: 3),
    boxShadow: [
      BoxShadow(
        color: Colors.blue.withOpacity(0.3),
        blurRadius: 10,
        spreadRadius: 2,
      ),
    ],
  ),
  child: Icon(Icons.home, color: Colors.white, size: 24),
)
```

## 🐛 Troubleshooting

### Common Issues
1. **Location Permission Denied**: Check app permissions in settings
2. **Map Not Loading**: Verify internet connection
3. **Location Not Updating**: Check GPS settings
4. **API Errors**: Verify server connectivity

### Debug Tips
- Enable location services in device settings
- Check internet connectivity
- Verify API endpoints are accessible
- Monitor console logs for errors

## 📈 Performance Optimization

### Location Updates
- **Smart Intervals**: 5-second update frequency
- **Battery Optimization**: Efficient location tracking
- **Network Efficiency**: Minimal data usage

### Map Performance
- **Tile Caching**: Cached map tiles for offline use
- **Marker Optimization**: Efficient marker rendering
- **Memory Management**: Proper resource cleanup

## 🔮 Future Enhancements

### Planned Features
- **Route Optimization**: Optimal delivery routes
- **Traffic Integration**: Real-time traffic data
- **Push Notifications**: Location-based alerts
- **Offline Maps**: Downloadable map regions

### Advanced Features
- **Heat Maps**: Delivery pattern analysis
- **Analytics**: Location tracking insights
- **Integration**: Third-party mapping services
- **Customization**: User-defined map styles

## 📞 Support

For technical support or feature requests, please contact the development team or create an issue in the project repository.

---

**Built with ❤️ for CureCart Mobile App**
