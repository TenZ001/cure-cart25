import 'package:flutter/material.dart';
import '../api_service.dart';
import '../delivery_partner_home.dart' show DeliveryOrderDetails; // reuse details widget
import 'location_tracking_screen.dart';
import 'dart:ui';

class DeliveryOrdersScreen extends StatefulWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  State<DeliveryOrdersScreen> createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends State<DeliveryOrdersScreen> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> assigned = [];
  String? partnerId;
  bool loading = true;

  String _extractId(Map<String, dynamic> m) {
    final dynamic raw = m['_id'] ?? m['id'] ?? m['orderId'];
    return raw == null ? '' : raw.toString();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Prefer delivery partner profile id from web
    final dp = await apiService.getDeliveryProfile();
    if (dp != null) {
      partnerId = (dp['_id']?.toString());
    } else {
      final user = await apiService.getUser();
      partnerId = user?["id"];
    }
    if (partnerId != null && partnerId!.isNotEmpty) {
      assigned = await apiService.getAssignedOrders(partnerId!);
      // Enrich from web (customer address/phone/payment) or fallback to backend contact endpoint
      for (int i = 0; i < assigned.length; i++) {
        final oid = _extractId(assigned[i]);
        if (oid != null && oid.isNotEmpty) {
          bool enriched = false;
          try {
            final det = await apiService.getOrderDetailsWeb(oid);
            if (det != null) {
              final p = det['prescription'] as Map<String, dynamic>?;
              final ord = det['order'] as Map<String, dynamic>?;
              if (p != null) {
                assigned[i]['customerAddress'] = p['customerAddress'] ?? assigned[i]['customerAddress'];
                assigned[i]['customerPhone'] = p['customerPhone'] ?? assigned[i]['customerPhone'];
                assigned[i]['paymentMethod'] = p['paymentMethod'] ?? assigned[i]['paymentMethod'];
                assigned[i]['customerName'] = p['patientName'] ?? assigned[i]['customerName'] ?? 'Customer';
                assigned[i]['pharmacy'] = p['pharmacyName'] ?? assigned[i]['pharmacy'];
                assigned[i]['pharmacyAddress'] = p['pharmacyAddress'] ?? assigned[i]['pharmacyAddress'];
                enriched = true;
              }
              if (ord != null) {
                if (ord['total'] != null) assigned[i]['total'] = ord['total'];
                // Use order-level address/payment when prescription fields are absent
                if (((assigned[i]['customerAddress'] ?? '').toString().isEmpty) && (ord['address'] != null)) {
                  assigned[i]['customerAddress'] = ord['address'];
                }
                if (((assigned[i]['paymentMethod'] ?? '').toString().isEmpty) && (ord['paymentMethod'] != null)) {
                  assigned[i]['paymentMethod'] = ord['paymentMethod'];
                }
                // Fetch customer details if missing phone/address and customerId exists
                final String? customerId = (ord['customerId'] ?? ord['customer']?['_id'])?.toString();
                if (customerId != null && customerId.isNotEmpty) {
                  try {
                    if (((assigned[i]['customerPhone'] ?? '').toString().isEmpty) || ((assigned[i]['customerAddress'] ?? '').toString().isEmpty) || ((assigned[i]['customerName'] ?? '').toString().isEmpty)) {
                      final cust = await apiService.getCustomerByIdWeb(customerId);
                      if (cust != null) {
                        assigned[i]['customerPhone'] = assigned[i]['customerPhone'] ?? cust['phone'];
                        assigned[i]['customerAddress'] = assigned[i]['customerAddress'] ?? cust['address'];
                        assigned[i]['customerName'] = assigned[i]['customerName'] ?? cust['name'];
                      }
                    }
                  } catch (_) {}
                }
                // Try to obtain pharmacy by id from DB to ensure address is present
                final String? pharmacyId = (ord['pharmacyId'] ?? ord['pharmacy']?['_id'])?.toString();
                if ((assigned[i]['pharmacyAddress'] ?? '').toString().isEmpty && pharmacyId != null && pharmacyId.isNotEmpty) {
                  try {
                    final ph = await apiService.getPharmacyById(pharmacyId);
                    if (ph != null) {
                      assigned[i]['pharmacy'] = assigned[i]['pharmacy'] ?? ph['name'];
                      assigned[i]['pharmacyAddress'] = ph['address'] ?? assigned[i]['pharmacyAddress'];
                    }
                  } catch (_) {}
                }
              }
            }
          } catch (_) {}
          // Always fetch backend contact to ensure user details are present
          try {
            final contact = await apiService.getOrderContact(oid);
            if (contact != null) {
              assigned[i]['customerAddress'] = contact['customer']?['address'] ?? contact['address'] ?? assigned[i]['customerAddress'];
              assigned[i]['customerPhone'] = contact['customer']?['phone'] ?? assigned[i]['customerPhone'];
              assigned[i]['customerName'] = contact['customer']?['name'] ?? assigned[i]['customerName'] ?? 'Customer';
            }
          } catch (_) {}
          // Also hydrate direct order fields from backend order (address/payment/pharmacy)
          try {
            final be = await apiService.getOrderById(oid);
            if (be != null) {
              if (((assigned[i]['customerAddress'] ?? '').toString().isEmpty) && (be['address'] != null)) {
                assigned[i]['customerAddress'] = be['address'];
              }
              if (((assigned[i]['paymentMethod'] ?? '').toString().isEmpty) && (be['paymentMethod'] != null)) {
                assigned[i]['paymentMethod'] = be['paymentMethod'];
              }
              if ((assigned[i]['pharmacy'] ?? '').toString().isEmpty && (be['pharmacy'] != null)) {
                assigned[i]['pharmacy'] = be['pharmacy'];
              }
              // If we still lack pharmacy address but have pharmacyId, look it up
              final String? pharmacyIdFromBe = (be['pharmacyId'] ?? be['pharmacy']?['_id'])?.toString();
              if ((assigned[i]['pharmacyAddress'] ?? '').toString().isEmpty && pharmacyIdFromBe != null && pharmacyIdFromBe.isNotEmpty) {
                try {
                  final ph = await apiService.getPharmacyById(pharmacyIdFromBe);
                  if (ph != null) {
                    assigned[i]['pharmacy'] = assigned[i]['pharmacy'] ?? ph['name'];
                    assigned[i]['pharmacyAddress'] = ph['address'] ?? assigned[i]['pharmacyAddress'];
                  }
                } catch (_) {}
              }
            }
          } catch (_) {}
        }
      }
    } else {
      assigned = [];
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Orders')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: assigned.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final order = assigned[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Row(
                        children: [
                          const Icon(Icons.local_shipping, size: 32, color: Colors.teal),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order['pharmacy'] ?? 'Pharmacy', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(order['address'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Builder(builder: (_) {
                                  final pharmacyAddress = ((order['pharmacyAddress'] ?? order['address']) ?? '').toString().trim();
                                  final text = pharmacyAddress.isEmpty ? '-' : pharmacyAddress;
                                  return Text('Pharmacy: $text', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black87));
                                }),
                                Builder(builder: (_) {
                                  final deliveryAddress = ((order['customerAddress'] ?? order['deliveryAddress'] ?? order['address']) ?? '').toString().trim();
                                  final text = deliveryAddress.isEmpty ? '-' : deliveryAddress;
                                  return Text('Delivery: $text', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black87));
                                }),
                                Builder(builder: (_) {
                                  final name = (order['customerName'] ?? '').toString().trim();
                                  final text = name.isEmpty ? '-' : name;
                                  return Text('Patient: $text', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.black87));
                                }),
                                Builder(builder: (_) {
                                  final phone = ((order['customerPhone'] ?? order['phone']) ?? '').toString().trim();
                                  final text = phone.isEmpty ? '-' : phone;
                                  return Text('Phone: $text', style: const TextStyle(fontSize: 12, color: Colors.black87));
                                }),
                                Row(
                                  children: [
                                    Builder(builder: (_) {
                                      final String rawOriginal = ((order['paymentMethod'] ?? '')).toString();
                                      final String raw = rawOriginal.toLowerCase();
                                      String label;
                                      if (raw.contains('cod') || raw.contains('cash')) {
                                        label = 'Cash on Delivery';
                                      } else if (raw.isNotEmpty) {
                                        label = 'Card';
                                      } else {
                                        label = '-';
                                      }
                                      return Text('Payment: $label', style: const TextStyle(fontSize: 12, color: Colors.black87));
                                    }),
                                    if (order['total'] != null) ...[
                                      const SizedBox(width: 12),
                                      Text('Total: Rs. ${order['total']}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                    ]
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Chip(label: Text(order['status'] ?? 'assigned')),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: (order['status'] == 'delivered') ? null : () {
                                        Navigator.push(
                                          context,
                            MaterialPageRoute(
                              builder: (context) => DeliveryLocationTrackingScreen(
                                orderId: _extractId(order),
                                              customerName: order['customerName'] ?? 'Customer',
                                              customerPhone: order['customerPhone'] ?? '',
                                              customerAddress: order['customerAddress'] ?? order['address'] ?? '',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.location_on, size: 16),
                                      label: Text(order['status'] == 'delivered' ? 'Delivered' : 'Track'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: order['status'] == 'delivered' ? Colors.grey : Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        textStyle: const TextStyle(fontSize: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DeliveryOrderDetails(
                                    orderId: _extractId(order),
                                    // Pass address data directly from assigned orders
                                    customerAddress: order['customerAddress'] ?? order['deliveryAddress'] ?? order['address'] ?? '',
                                    pharmacyAddress: order['pharmacyAddress'] ?? order['address'] ?? '',
                                    customerPhone: order['customerPhone'] ?? order['phone'] ?? '',
                                    customerName: order['customerName'] ?? 'Customer',
                                    paymentMethod: order['paymentMethod'] ?? '',
                                    pharmacyName: order['pharmacy'] ?? 'Unknown Pharmacy',
                                  ),
                                ),
                              );
                              _load();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                },
              ),
            ),
      bottomNavigationBar: _footer(context, 1),
    );
  }

  Widget _footer(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
      ],
      onTap: (i) {
        switch (i) {
          case 0:
            Navigator.pushReplacementNamed(context, '/deliveryDashboard');
            break;
          case 1:
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/deliveryHistory');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/deliveryNotifications');
            break;
        }
      },
    );
  }
}


