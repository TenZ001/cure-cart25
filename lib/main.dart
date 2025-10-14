import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'prescription.dart';
import 'my_orders.dart';
import 'med_scan.dart';
import 'upload_prescription.dart';
import 'delivery/signup_screen.dart';
import 'delivery_partner_home.dart';
import 'delivery/dashboard.dart';
import 'delivery/orders_screen.dart';
import 'delivery/history_screen.dart';
import 'delivery/notifications_screen.dart';
import 'location_test.dart';
import 'pickup_test.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(), // Added home screen route
        '/prescription': (context) => const PrescriptionScreen(),
        '/orders': (context) => const MyOrdersPage(purchasedOrders: [], pendingOrders: []),
        '/medscan': (context) => const MedScanPage(),
        '/upload': (context) => const UploadPrescriptionScreen(),
        '/delivery-signup': (context) => const DeliverySignupScreen(),
        '/deliveryHome': (context) => const DeliveryPartnerHome(),
        '/deliveryDashboard': (context) => const DeliveryDashboard(),
        '/deliveryOrders': (context) => const DeliveryOrdersScreen(),
        '/deliveryHistory': (context) => const DeliveryHistoryScreen(),
        '/deliveryNotifications': (context) => const DeliveryNotificationsScreen(),
        '/locationTest': (context) => const LocationTestScreen(),
        '/pickupTest': (context) => PickupTestScreen(orderId: 'test-order-id'),
      },
    );
  }
}
