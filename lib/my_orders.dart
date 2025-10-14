// file: lib/my_orders.dart
import 'package:flutter/material.dart';
import 'app_bottom_nav.dart';
import 'track_order.dart'; // ✅ import track order
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class MyOrdersPage extends StatefulWidget {
  final List<Map<String, dynamic>> purchasedOrders;
  final List<Map<String, dynamic>> pendingOrders;

  const MyOrdersPage({
    Key? key,
    required this.purchasedOrders,
    required this.pendingOrders,
  }) : super(key: key);

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _allOrders = [];
  final ApiService _api = ApiService();
  // Persistently hide deleted orders across refreshes
  Set<String> _hiddenOrderIds = <String>{};

  String _extractId(Map<String, dynamic> order) {
    final dynamic raw = order['_id'] ?? order['id'] ?? order['orderId'];
    return raw == null ? '' : raw.toString();
  }

  String _extractStatus(Map<String, dynamic> order) {
    // Try multiple common keys used by backend/web
    final dynamic s = order['status'] ?? order['orderStatus'] ?? order['state'] ?? order['deliveryStatus'];
    if (s != null && s.toString().isNotEmpty) return s.toString();
    // If explicit confirmation booleans/flags exist
    if (order['confirmed'] == true || order['isConfirmed'] == true) return 'confirmed';
    return 'pending';
  }

  String _statusFromDetails(Map<String, dynamic> details, String fallback) {
    // Flatten potentially nested structure
    final Map<String, dynamic> d = Map<String, dynamic>.from(details);
    final Map<String, dynamic>? pres = d['prescription'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(d['prescription'])
        : null;
    final dynamic delivered = d['delivered'] ?? d['isDelivered'] ?? pres?['delivered'];
    final dynamic picked = d['pickedUp'] ?? d['isPickedUp'] ?? pres?['pickedUp'];
    final dynamic confirmed = d['confirmed'] ?? d['isConfirmed'] ?? pres?['confirmed'];
    final String? status = d['status']?.toString() ?? pres?['status']?.toString();

    if (delivered == true || (status != null && status.toLowerCase() == 'delivered')) {
      return 'delivered';
    }
    if (picked == true || (status != null && (status.toLowerCase() == 'out_for_delivery' || status.toLowerCase() == 'out-for-delivery' || status.toLowerCase() == 'out for delivery' || status.toLowerCase() == 'assigned'))) {
      return 'dispatched';
    }
    if (confirmed == true || (status != null && (status.toLowerCase() == 'confirmed' || status.toLowerCase() == 'accepted' || status.toLowerCase().contains('confirm')))) {
      return 'processing';
    }
    return _normalizeStatus(status ?? fallback);
  }

  String _normalizeStatus(String? status) {
    final s = (status ?? 'pending').toLowerCase();
    switch (s) {
      case 'ordered':
      case 'confirmed':
      case 'accepted':
      case 'confirm delivery':
      case 'confirm-delivery':
      case 'confirm_delivery':
      case 'delivery confirmed':
      case 'delivery-confirmed':
      case 'delivery_confirmed':
        return 'processing';
      case 'assigned':
      case 'out_for_delivery':
      case 'out-for-delivery':
      case 'out for delivery':
        return 'dispatched';
      case 'completed':
        return 'delivered';
      default:
        return s;
    }
  }

  @override
  void initState() {
    super.initState();
    // Load orders on open
    Future.microtask(_loadOrders);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen regains focus
    _loadOrders();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      // Load hidden/deleted order ids
      final List<String> hidden = prefs.getStringList('hidden_orders') ?? <String>[];
      _hiddenOrderIds = hidden.toSet();
      final List<String> savedOrders = prefs.getStringList('user_orders') ?? [];
      final List<Map<String, dynamic>> localOrders = [];
      for (final s in savedOrders) {
        try {
          final parsed = jsonDecode(s) as Map<String, dynamic>;
          localOrders.add(parsed);
        } catch (_) {}
      }
      // Build map from local first
      final Map<String, Map<String, dynamic>> idToOrder = {};
      for (final o in localOrders) {
        final oid = _extractId(o);
        if (oid.isNotEmpty && !_hiddenOrderIds.contains(oid) && !idToOrder.containsKey(oid)) {
          idToOrder[oid] = Map<String, dynamic>.from(o);
        }
      }

      // Fetch from API and merge statuses
      try {
        final user = await _api.getUser();
        final String? customerId = user != null ? user['id'] as String? : null;
        if (customerId != null && customerId.isNotEmpty) {
          final apiOrders = await _api.getCustomerOrders(customerId);
          for (final apiOrder in apiOrders) {
            final oid = _extractId(apiOrder);
            if (oid.isEmpty) continue;
            if (_hiddenOrderIds.contains(oid)) continue; // skip hidden orders
            final normalizedStatus = _normalizeStatus(_extractStatus(apiOrder));

            if (idToOrder.containsKey(oid)) {
              // Update status and enrich details from API
              idToOrder[oid]![
                'status'
              ] = normalizedStatus;
              if (apiOrder['items'] is List) idToOrder[oid]!['items'] = apiOrder['items'];
              if (apiOrder['total'] != null) idToOrder[oid]!['total'] = apiOrder['total'];
              if (apiOrder['pharmacy'] != null) idToOrder[oid]!['pharmacy'] = apiOrder['pharmacy'];
              if (apiOrder['pharmacyId'] != null) idToOrder[oid]!['pharmacyId'] = apiOrder['pharmacyId'];
              if (apiOrder['address'] != null) idToOrder[oid]!['address'] = apiOrder['address'];
              if (apiOrder['paymentMethod'] != null) idToOrder[oid]!['paymentMethod'] = apiOrder['paymentMethod'];
              if (apiOrder['createdAt'] != null) idToOrder[oid]!['createdAt'] = apiOrder['createdAt'];
              // Also keep `_id`/`id` consistent
              idToOrder[oid]!['_id'] = oid;
              idToOrder[oid]!['id'] = oid;
            } else {
              // Attempt to re-associate any locally-created placeholder orders (id starts with 'local_')
              String? localKeyMatch;
              try {
                final apiTotal = apiOrder['total']?.toString();
                final apiItems = (apiOrder['items'] is List) ? (apiOrder['items'] as List) : const [];
                final String? apiFirstName = apiItems.isNotEmpty ? (apiItems.first['name']?.toString()) : null;
                for (final entry in idToOrder.entries) {
                  final k = entry.key;
                  if (!k.startsWith('local_')) continue;
                  final local = entry.value;
                  final localTotal = local['total']?.toString();
                  final localItems = (local['items'] is List) ? (local['items'] as List) : const [];
                  final String? localFirstName = localItems.isNotEmpty ? (localItems.first['name']?.toString()) : (local['name']?.toString());
                  final bool totalMatches = apiTotal != null && localTotal != null && apiTotal == localTotal;
                  final bool nameMatches = apiFirstName != null && localFirstName != null && apiFirstName.toLowerCase() == localFirstName.toLowerCase();
                  if (totalMatches && nameMatches) {
                    localKeyMatch = k;
                    break;
                  }
                }
              } catch (_) {}

              if (localKeyMatch != null) {
                // Replace local placeholder with API order using real id
                final localOrder = idToOrder.remove(localKeyMatch!)!;
                localOrder['_id'] = oid;
                localOrder['id'] = oid;
                localOrder['status'] = normalizedStatus;
                if (apiOrder['items'] is List) localOrder['items'] = apiOrder['items'];
                if (apiOrder['pharmacy'] != null) localOrder['pharmacy'] = apiOrder['pharmacy'];
                if (apiOrder['pharmacyId'] != null) localOrder['pharmacyId'] = apiOrder['pharmacyId'];
                if (apiOrder['address'] != null) localOrder['address'] = apiOrder['address'];
                if (apiOrder['paymentMethod'] != null) localOrder['paymentMethod'] = apiOrder['paymentMethod'];
                if (apiOrder['createdAt'] != null) localOrder['createdAt'] = apiOrder['createdAt'];
                if (!_hiddenOrderIds.contains(oid)) {
                  idToOrder[oid] = localOrder;
                }
              } else {
              // Add API order in our local display format
              if (!_hiddenOrderIds.contains(oid)) {
                idToOrder[oid] = {
                '_id': oid,
                'id': oid,
                'name': (apiOrder['items'] is List && (apiOrder['items'] as List).isNotEmpty)
                    ? ((apiOrder['items'] as List).first['name'] ?? 'Order')
                    : (apiOrder['name'] ?? 'Order'),
                'items': apiOrder['items'] ?? [],
                'total': apiOrder['total'],
                'status': normalizedStatus,
                'pharmacy': apiOrder['pharmacy'],
                'pharmacyId': apiOrder['pharmacyId'],
                'address': apiOrder['address'],
                'paymentMethod': apiOrder['paymentMethod'],
                'createdAt': apiOrder['createdAt'] ?? DateTime.now().toIso8601String(),
              };
              }
              }
            }
          }
        }
      } catch (_) {}

      // Also merge any passed-in orders for backward compatibility
      for (final o in widget.purchasedOrders + widget.pendingOrders) {
        final oid = _extractId(o);
        if (oid.isEmpty) continue;
        if (!_hiddenOrderIds.contains(oid)) {
          idToOrder.putIfAbsent(oid, () => Map<String, dynamic>.from(o));
        }
      }

      // For likely-changing orders, fetch detailed status from web and update
      try {
        final pendingIds = idToOrder.values
            .where((o) {
              final s = (o['status'] ?? 'pending').toString().toLowerCase();
              return s == 'pending' || s == 'ordered' || s == 'confirmed' || s == 'accepted';
            })
            .map(_extractId)
            .where((id) => id.isNotEmpty && !id.startsWith('local_'))
            .toList();

        // Limit to a few recent to avoid excessive calls
        for (final oid in pendingIds.take(5)) {
          try {
            final details = await _api.getOrderDetailsWeb(oid);
            if (details != null) {
              final current = idToOrder[oid];
              if (current != null) {
                final updatedStatus = _statusFromDetails(details, (current['status'] ?? 'pending').toString());
                current['status'] = updatedStatus;
              }
            }
          } catch (_) {}
        }
      } catch (_) {}

      // Build final combined list AFTER status/detail merging
      // Filter out hidden one last time (safety)
      final combined = idToOrder.entries
          .where((e) => !_hiddenOrderIds.contains(e.key))
          .map((e) => e.value)
          .toList();

      // Persist merged orders locally
      try {
        final strings = combined.map((o) => jsonEncode(o)).toList();
        await prefs.setStringList('user_orders', strings);
      } catch (_) {}

      setState(() {
        _allOrders = combined;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveLocalOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final strings = _allOrders.map((o) => jsonEncode(o)).toList();
      await prefs.setStringList('user_orders', strings);
    } catch (_) {}
  }

  Future<void> _confirmDelete(String orderId) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete order?'),
        content: const Text('This will permanently delete the order.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _deleteOrder(orderId);
    }
  }

  Future<void> _deleteOrder(String orderId) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleting order...')),
        );
      }

      // Call web API to permanently delete
      final ok = await _api.deleteOrderWeb(orderId);
      
      if (!ok) {
        print('❌ Failed to delete order $orderId from server');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete from server. Order will be hidden locally.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        print('✅ Successfully deleted order $orderId from server');
      }

      // Remove locally regardless of server response
      setState(() {
        _allOrders = _allOrders.where((o) => _extractId(o) != orderId).toList();
      });

      // Persistently hide this order id across refreshes
      try {
        final prefs = await SharedPreferences.getInstance();
        final List<String> hidden = prefs.getStringList('hidden_orders') ?? <String>[];
        if (!hidden.contains(orderId)) {
          hidden.add(orderId);
          await prefs.setStringList('hidden_orders', hidden);
        }
        _hiddenOrderIds.add(orderId);
        print('✅ Added order $orderId to hidden list');
      } catch (e) {
        print('❌ Error saving hidden orders: $e');
      }

      // Persist local orders
      await _saveLocalOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Order deleted successfully' : 'Order hidden locally'),
            backgroundColor: ok ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Error deleting order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting order. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _purchasedOrders {
    return _allOrders.where((order) {
      final status = (order['status'] ?? 'pending').toString().toLowerCase();
      return status == 'pending' || status == 'processing' || status == 'dispatched' || status == 'delivered';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _purchasedOrders.isEmpty
              ? const Center(child: Text("No purchased orders yet"))
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    itemCount: _purchasedOrders.length,
                    itemBuilder: (context, index) {
                      final order = _purchasedOrders[index];
                      return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Leading icon
                            const Padding(
                              padding: EdgeInsets.only(right: 12.0, top: 4.0),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.black54,
                                size: 32,
                              ),
                            ),
                            // Main content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title
                                  Text(
                                    order['name'] ?? "Unknown",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  // Medicine names
                                  if (order['items'] != null && (order['items'] as List).isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Text(
                                        ((order['items'] as List).map((i) => (i['name'] ?? '')).toList()).join(', '),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                      ),
                                    ),
                                  // Price and quantity
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      "Rs. ${order['total'] ?? order['price']}" + (order['qty'] != null ? " • Qty: ${order['qty']}" : ""),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  // Pharmacy
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      "Pharmacy: ${order['pharmacy'] ?? 'No pharmacy'}",
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Address
                                  if (((order['address'] ?? order['customerAddress']) ?? '').toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Text(
                                        "Pharmacy Address: ${order['address'] ?? order['customerAddress']}",
                                        style: const TextStyle(fontSize: 14),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  // Payment method
                                  Builder(builder: (_) {
                                    final rawOriginal = (order['paymentMethod'] ?? '').toString();
                                    final raw = rawOriginal.toLowerCase();
                                    String label = '';
                                    if (raw.contains('cod') || raw.contains('cash')) {
                                      label = 'Cash on Delivery';
                                    } else if (raw.isNotEmpty) {
                                      label = 'Card';
                                    }
                                    return label.isEmpty 
                                      ? const SizedBox.shrink() 
                                      : Padding(
                                          padding: const EdgeInsets.only(bottom: 4.0),
                                          child: Text(
                                            'Payment: $label',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        );
                                  }),
                                  // Status
                                  if (order['status'] != null)
                                    Builder(builder: (_) {
                                      final String rawStatus = (order['status'] ?? '').toString();
                                      final String s = rawStatus.toLowerCase();
                                      final String display = s == 'picked_up' ? 'picked up by delivery' : rawStatus;
                                      final Color color = s == 'pending'
                                          ? Colors.orange
                                          : (s == 'processing' || s == 'picked_up')
                                              ? Colors.blue
                                              : (s == 'delivered')
                                                  ? Colors.green
                                                  : Colors.grey;
                                      return Text(
                                        "Status: $display",
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                            // Trailing actions
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  tooltip: 'Delete',
                                  onPressed: () {
                                    final String orderId = _extractId(order);
                                    if (orderId.isNotEmpty) {
                                      _confirmDelete(orderId);
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () {
                                    final String orderId =
                                        (order['id'] ?? order['_id'] ?? 'demo').toString();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TrackOrderPage(orderId: orderId),
                                      ),
                                    );
                                  },
                                  child: const Text("Track Order"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}
