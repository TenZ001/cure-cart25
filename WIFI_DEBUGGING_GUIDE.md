# WiFi Debugging Setup Guide for Cure Cart Mobile

## Issues Fixed

1. **Gradle Configuration Issues**: Fixed deprecated properties and plugin compatibility
2. **Network Security**: Added cleartext traffic permissions for WiFi debugging
3. **Android Manifest**: Added necessary permissions for WiFi and network access
4. **Network Security Config**: Created XML configuration for local network debugging

## WiFi Debugging Setup

### 1. Enable WiFi Debugging on Android Device
1. Enable Developer Options on your Android device
2. Enable "USB Debugging" 
3. Enable "Wireless debugging" (Android 11+)
4. Connect device to same WiFi network as your development machine

### 2. Connect via WiFi
```bash
# First connect via USB to enable WiFi debugging
adb devices

# Enable WiFi debugging (Android 11+)
adb tcpip 5555

# Connect via WiFi (replace IP_ADDRESS with your device's IP)
adb connect IP_ADDRESS:5555

# Verify connection
adb devices
```

### 3. Run Flutter App via WiFi
```bash
# Run on connected device
flutter run -d <device_id>

# Or run on all devices
flutter run -d all
```

## Network Configuration

The following files have been configured for WiFi debugging:

### AndroidManifest.xml
- Added WiFi and network permissions
- Enabled cleartext traffic for local debugging
- Added network security configuration

### network_security_config.xml
- Allows cleartext traffic for localhost and common development IPs
- Supports debugging on local network

### gradle.properties
- Updated JVM settings for better performance
- Fixed deprecated properties

## Troubleshooting

### If WiFi connection fails:
1. Ensure device and computer are on same WiFi network
2. Check firewall settings
3. Try different port (5556, 5557, etc.)
4. Restart ADB: `adb kill-server && adb start-server`

### If Gradle build fails:
1. Clean project: `flutter clean`
2. Get dependencies: `flutter pub get`
3. Rebuild: `flutter build apk --debug`

### If device not detected:
1. Check ADB connection: `adb devices`
2. Verify WiFi debugging is enabled
3. Check IP address is correct
4. Try USB connection first, then switch to WiFi
