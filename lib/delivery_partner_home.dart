import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryPartnerHome extends StatelessWidget {
  const DeliveryPartnerHome({super.key});

  @override
  Widget build(BuildContext context) {
    // Backward-compat: redirect to new dashboard
    return const _RedirectToDashboard();
  }
}

class _RedirectToDashboard extends StatefulWidget {
  const _RedirectToDashboard();

  @override
  State<_RedirectToDashboard> createState() => _RedirectToDashboardState();
}

class _RedirectToDashboardState extends State<_RedirectToDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/deliveryDashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class DeliveryOrderDetails extends StatefulWidget {
  final String orderId;
  final String? customerAddress;
  final String? pharmacyAddress;
  final String? customerPhone;
  final String? customerName;
  final String? paymentMethod;
  final String? pharmacyName;
  
  const DeliveryOrderDetails({
    super.key, 
    required this.orderId,
    this.customerAddress,
    this.pharmacyAddress,
    this.customerPhone,
    this.customerName,
    this.paymentMethod,
    this.pharmacyName,
  });

  @override
  State<DeliveryOrderDetails> createState() => _DeliveryOrderDetailsState();
}

class _DeliveryOrderDetailsState extends State<DeliveryOrderDetails> {
  final ApiService apiService = ApiService();
  Map<String, dynamic>? order;
  Map<String, dynamic>? contact;
  bool loading = true;
  bool _picked = false;
  bool _delivered = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Use passed data first (from assigned orders page)
    order = {};
    contact = {};
    
    // Set pharmacy info from passed data
    if (widget.pharmacyName != null && widget.pharmacyName!.isNotEmpty) {
      order!['pharmacy'] = widget.pharmacyName;
    }
    if (widget.pharmacyAddress != null && widget.pharmacyAddress!.isNotEmpty) {
      order!['pharmacyAddress'] = widget.pharmacyAddress;
    }
    if (widget.paymentMethod != null && widget.paymentMethod!.isNotEmpty) {
      order!['paymentMethod'] = widget.paymentMethod;
    }
    
    // Set customer info from passed data
    contact!['customer'] = {};
    if (widget.customerName != null && widget.customerName!.isNotEmpty) {
      contact!['customer']['name'] = widget.customerName;
    }
    if (widget.customerPhone != null && widget.customerPhone!.isNotEmpty) {
      contact!['customer']['phone'] = widget.customerPhone;
    }
    if (widget.customerAddress != null && widget.customerAddress!.isNotEmpty) {
      contact!['customer']['address'] = widget.customerAddress;
      contact!['address'] = widget.customerAddress;
    }
    
    // Only make API calls for additional data not passed from assigned orders
    try {
      final web = await apiService.getOrderDetailsWeb(widget.orderId);
      if (web != null) {
        final pres = web['prescription'] as Map<String, dynamic>?;
        final ord = web['order'] as Map<String, dynamic>?;
        if (pres != null) {
          order ??= {};
          order!['pharmacy'] = pres['pharmacyName'] ?? order?['pharmacy'];
          // Keep pharmacy address separate from delivery address
          order!['pharmacyAddress'] = pres['pharmacyAddress'] ?? order?['pharmacyAddress'];
          order!['paymentMethod'] = pres['paymentMethod'] ?? order?['paymentMethod'];
          // Merge minimal customer info into contact-like structure
          contact ??= {};
          contact!['customer'] = (contact?['customer'] as Map<String, dynamic>?) ?? {};
          (contact!['customer'] as Map<String, dynamic>)['name'] = (contact?['customer']?['name']) ?? '';
          (contact!['customer'] as Map<String, dynamic>)['phone'] = pres['customerPhone'] ?? (contact?['customer']?['phone']);
          // Put delivery address under customer.address and keep a top-level fallback
          (contact!['customer'] as Map<String, dynamic>)['address'] = pres['customerAddress'] ?? (contact?['customer']?['address']);
          contact!['address'] = contact?['address'] ?? pres['customerAddress'];
        }
        if (ord != null) {
          // Hydrate total/price
          if (ord['total'] != null) {
            order ??= {};
            order!['total'] = ord['total'];
          }
          // Fill address/payment from order when prescription missing
          if ((contact?['customer']?['address'] == null) && (ord['address'] != null)) {
            contact ??= {};
            contact!['address'] = ord['address'];
            contact!['customer'] = (contact!['customer'] as Map<String, dynamic>?) ?? {};
            (contact!['customer'] as Map<String, dynamic>)['address'] = ord['address'];
          }
          if ((order?['paymentMethod'] == null) && (ord['paymentMethod'] != null)) {
            order ??= {};
            order!['paymentMethod'] = ord['paymentMethod'];
          }
          // Ensure pharmacy name/address using DB when available
          try {
            final String? pharmacyId = (ord['pharmacyId'] ?? ord['pharmacy']?['_id'])?.toString();
            if (pharmacyId != null && pharmacyId.isNotEmpty) {
              final ph = await apiService.getPharmacyById(pharmacyId);
              if (ph != null) {
                order ??= {};
                order!['pharmacy'] = order?['pharmacy'] ?? ph['name'];
                order!['pharmacyAddress'] = order?['pharmacyAddress'] ?? ph['address'];
              }
            }
          } catch (_) {}
          // Fetch customer details if missing
          try {
            final String? customerId = (ord['customerId'] ?? ord['customer']?['_id'])?.toString();
            if (customerId != null && customerId.isNotEmpty) {
              final cust = await apiService.getCustomerByIdWeb(customerId);
              if (cust != null) {
                contact ??= {};
                contact!['customer'] = (contact?['customer'] as Map<String, dynamic>?) ?? {};
                (contact!['customer'] as Map<String, dynamic>)['name'] = (contact!['customer'] as Map<String, dynamic>)['name'] ?? cust['name'];
                (contact!['customer'] as Map<String, dynamic>)['phone'] = (contact!['customer'] as Map<String, dynamic>)['phone'] ?? cust['phone'];
                (contact!['customer'] as Map<String, dynamic>)['address'] = (contact!['customer'] as Map<String, dynamic>)['address'] ?? cust['address'];
              }
            }
          } catch (_) {}
          // Hydrate picked-up flag
          final tracking = ord['tracking'] as Map<String, dynamic>?;
          final pickedUpAt = tracking != null ? tracking['pickedUpAt'] : null;
          if ((pickedUpAt is String && pickedUpAt.isNotEmpty) || pickedUpAt is DateTime) {
            _picked = true;
          }
          // Hydrate delivered flag
          if (ord['status'] == 'delivered') {
            _delivered = true;
          }
        }
      }
    } catch (_) {}
    setState(() {
      loading = false;
    });
  }

  Future<void> _updateStatus(String status) async {
    final ok = await apiService.updateDeliveryStatus(widget.orderId, status);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated: $status')),
      );
      _load();
    }
  }

  Future<void> _confirmDelivered() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Confirming delivery...'),
            ],
          ),
        ),
      );

      // Update delivery status to delivered (this now handles all updates)
      final ok = await apiService.updateDeliveryStatus(widget.orderId, 'delivered');
      print('Delivery status update result: $ok');
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      if (ok && mounted) {
        setState(() => _delivered = true);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delivery Completed'),
            content: const Text('Order marked as delivered. Payment status updated to paid.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to confirm delivery. Please try again.')),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      
      print('Error confirming delivery: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _openPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0,4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.local_hospital, color: Colors.teal),
                          const SizedBox(width: 8),
                          Expanded(child: Text(order?["pharmacy"] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black))),
                        ]),
                        if (_picked) ...[
                          const SizedBox(height: 6),
                          Row(children: const [
                            Icon(Icons.check_circle, color: Colors.orange, size: 18),
                            SizedBox(width: 6),
                            Text('Picked up', style: TextStyle(color: Colors.black87, fontSize: 13)),
                          ]),
                        ],
                        const SizedBox(height: 8),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.gps_fixed, color: Colors.redAccent, size: 18),
                          const SizedBox(width: 6),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Customer Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                              Text(
                                ((contact?['customer']?['address'])
                                    ?? (contact?['address'])
                                    ?? (order?['customerAddress'])
                                    ?? (order?['deliveryAddress'])
                                    ?? (order?['address'])
                                    ?? '-').toString(),
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                            ],
                          )),
                        ]),
                        const SizedBox(height: 6),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.local_hospital, color: Colors.teal, size: 18),
                          const SizedBox(width: 6),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pharmacy Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                              Text(
                                ((order?['pharmacyAddress']) ?? (order?['address']) ?? '-').toString(),
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                            ],
                          )),
                        ]),
                        const SizedBox(height: 6),
                        // Payment method
                        Builder(builder: (_) {
                          final rawOriginal = ((order?["paymentMethod"]) ?? (contact?["paymentMethod"]) ?? (order?["payment"]))?.toString() ?? '';
                          final raw = rawOriginal.toLowerCase();
                          String label;
                          if (raw.contains('cod') || raw.contains('cash')) {
                            label = 'Cash on Delivery';
                          } else if (raw.isEmpty) {
                            label = '-';
                          } else {
                            label = 'Card';
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.payment, color: Colors.deepPurple, size: 18),
                              const SizedBox(width: 6),
                              const Text('Payment: ', style: TextStyle(fontSize: 13, color: Colors.black87)),
                              Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
                            ],
                          );
                        }),
                        const SizedBox(height: 6),
                        // Price / Total
                        Builder(builder: (_) {
                          final total = order?['total'];
                          double? value;
                          if (total is num) value = total.toDouble();
                          final display = value != null ? 'Rs. ${value.toStringAsFixed(2)}' : '-';
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.attach_money, color: Colors.green, size: 18),
                              const SizedBox(width: 6),
                              const Text('Price: ', style: TextStyle(fontSize: 13, color: Colors.black87)),
                              Text(display, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
                            ],
                          );
                        }),
                        const SizedBox(height: 6),
                        if (contact != null
                            || ((order?['customerAddress'] ?? order?['address'] ?? '').toString().isNotEmpty)
                            || ((order?['customerPhone'] ?? order?['phone'] ?? '').toString().isNotEmpty)
                            || ((order?['customerName'] ?? '').toString().isNotEmpty)) ...[
                          Row(children: [
                            const Icon(Icons.person, color: Colors.indigo, size: 18),
                            const SizedBox(width: 6),
                            Expanded(child: Text('Customer: ${contact?["customer"]?["name"] ?? order?["customerName"] ?? '-'}', style: const TextStyle(fontSize: 13, color: Colors.black87))),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.phone, color: Colors.green, size: 18),
                            const SizedBox(width: 6),
                            Expanded(child: Text('Phone: ${contact?["customer"]?["phone"] ?? order?["customerPhone"] ?? order?["phone"] ?? '-'}', style: const TextStyle(fontSize: 13, color: Colors.black87))),
                          ]),
                          // Bottom customer address removed (kept top GPS section only)
                        ],
                        const SizedBox(height: 10),
                        // Only show action buttons if order is not delivered
                        if (order?['status'] != 'delivered') ...[
                          Row(children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _picked ? null : () async {
                                  // Try the simpler status update approach first
                                  final ok = await apiService.updateDeliveryStatus(widget.orderId, 'dispatched');
                                  if (!mounted) return;
                                  if (ok) {
                                    setState(()=> _picked = true);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Order marked as picked up and dispatched')),
                                    );
                                    _load(); // Refresh to get updated status
                                  } else {
                                    // If that fails, try the web API method
                                    final webOk = await apiService.markOrderPickedUpWeb(widget.orderId);
                                    if (webOk) {
                                      setState(()=> _picked = true);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Order marked as picked up and dispatched')),
                                      );
                                      _load();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to mark picked up')));
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: _picked ? Colors.orangeAccent : null,
                                ),
                                child: const Text('Picked Up'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _delivered ? null : _confirmDelivered,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: _delivered ? Colors.grey : null,
                                ),
                                child: Text(_delivered ? 'Delivered' : 'Confirm Delivered'),
                              ),
                            ),
                          ]),
                        ] else ...[
                          // Show delivered status when order is delivered
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Order Delivered Successfully',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (contact != null) Row(children: [
                          TextButton.icon(onPressed: () => _openPhone('${contact?["customer"]?["phone"] ?? ''}'), icon: const Icon(Icons.call), label: const Text('Call Customer')),
                          const SizedBox(width: 6),
                          if (contact?["customerLat"] != null && contact?["customerLng"] != null)
                            TextButton.icon(onPressed: () => _openMaps((contact?["customerLat"] as num).toDouble(), (contact?["customerLng"] as num).toDouble()), icon: const Icon(Icons.map), label: const Text('Open in Maps')),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}


