import 'dart:io';

class ApiConfig {
  // Emulator (Android)
  static const String emulatorBaseUrl = "http://10.0.2.2:5000/api";
  static const String emulatorWebBaseUrl = "http://10.0.2.2:4000/api";

  // LAN (for real device testing) → your machine's IP
  static const String localNetworkBaseUrl = "http://172.20.10.3:5000/api";
  static const String localNetworkWebBaseUrl = "http://172.20.10.3:4000/api";

  //static const String localNetworkBaseUrl = "http://192.168.17.176:5000/api";
  //static const String localNetworkWebBaseUrl = "http://192.168.17.176:4000/api";

  // Alternative LAN IP
  static const String localNetworkBaseUrl2 = "http://192.168.17.176:5000/api";
  static const String localNetworkWebBaseUrl2 = "http://192.168.17.176:4000/api";

  // Production (deployed backend)
  static const String productionBaseUrl = "https://your-app.onrender.com/api";
  static const String productionWebBaseUrl = "https://your-web.onrender.com/api";

  // Ngrok tunnel URLs (replace with your actual ngrok URLs)
  static const String ngrokBaseUrl = "https://interfascicular-nondepartmental-herma.ngrok-free.dev/api";
static const String ngrokWebBaseUrl = "https://interfascicular-nondepartmental-herma.ngrok-free.dev/api";

  // Optional: allow overriding via --dart-define
  static const String customBaseUrl =
      String.fromEnvironment("API_BASE_URL", defaultValue: "");
  static const String customWebBaseUrl =
      String.fromEnvironment("WEB_API_BASE_URL", defaultValue: "");

  static String get baseUrl {
    // If provided via --dart-define, use that
    if (customBaseUrl.isNotEmpty) {
      return customBaseUrl;
    }

    if (Platform.isAndroid) {
      // Use your current Wi-Fi IP
      return localNetworkBaseUrl; // 172.20.10.3
    } else if (Platform.isIOS) {
      // iOS Simulator works with localhost
      return "http://localhost:5000/api";
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Flutter desktop/web testing
      return "http://localhost:5000/api";
    } else {
      // Real devices → use ngrok tunnel
      return ngrokBaseUrl;
    }
  }

  static String get webBaseUrl {
    if (customWebBaseUrl.isNotEmpty) {
      return customWebBaseUrl;
    }

    if (Platform.isAndroid) {
      // Use the same IP as baseUrl for consistency
      return localNetworkWebBaseUrl; // 172.20.10.3
    } else if (Platform.isIOS) {
      return "http://localhost:4000/api";
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return "http://localhost:4000/api";
    } else {
      return ngrokWebBaseUrl;
    }
  }
}
