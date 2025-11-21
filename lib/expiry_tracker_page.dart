import 'package:firebase_auth/firebase_auth.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'localization/app_localizations.dart';

class ExpiryTrackerPage extends StatefulWidget {
  const ExpiryTrackerPage({super.key});

  @override
  State<ExpiryTrackerPage> createState() => _ExpiryTrackerPageState();
}

class _ExpiryTrackerPageState extends State<ExpiryTrackerPage> {
  bool _isCustomer = false;
  List<_ExpiryInfo> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _items = [];
        _isLoading = false;
      });
      return;
    }

    final pharmacistSnapshot = await DatabaseService.instance
        .ref('pharmacy/pharmacists/${user.uid}')
        .get();

    List<_ExpiryInfo> items;
    if (pharmacistSnapshot.exists) {
      _isCustomer = false;
      items = await _loadPharmacistInventory(user.uid);
    } else {
      _isCustomer = true;
      items = await _loadCustomerOrders(user.uid);
    }

    setState(() {
      _items = items;
      _isLoading = false;
    });

    // Check for expired medicines and send notifications (for customers only)
    if (_isCustomer) {
      _checkAndNotifyExpiredMedicines(user.uid, items);
    }
  }

  Future<void> _checkAndNotifyExpiredMedicines(String customerId, List<_ExpiryInfo> items) async {
    try {
      final now = DateTime.now();
      final expiredItems = items.where((item) => item.daysRemaining <= 0).toList();
      final expiringSoonItems = items.where((item) => item.daysRemaining > 0 && item.daysRemaining <= 7).toList();

      // Check if we've already notified about these items today
      final lastNotificationRef = DatabaseService.instance
          .ref('customer_expiry_notifications/$customerId/lastCheck');
      final lastCheckSnapshot = await lastNotificationRef.get();
      
      DateTime? lastCheck;
      if (lastCheckSnapshot.exists) {
        final lastCheckStr = lastCheckSnapshot.value?.toString();
        if (lastCheckStr != null) {
          lastCheck = DateTime.tryParse(lastCheckStr);
        }
      }

      final today = DateTime(now.year, now.month, now.day);
      final lastCheckDate = lastCheck != null 
          ? DateTime(lastCheck.year, lastCheck.month, lastCheck.day)
          : null;

      // Only send notifications once per day
      if (lastCheckDate != null && lastCheckDate.isAtSameMomentAs(today)) {
        return;
      }

      // Send notification for expired medicines
      if (expiredItems.isNotEmpty) {
        final productNames = expiredItems.map((item) => item.productName).join(', ');
        await NotificationService.notifyCustomer(
          customerId: customerId,
          title: 'Medicines expired',
          body: 'The following medicines have expired: $productNames. Please dispose of them safely.',
          type: 'medicine_expired',
          data: {
            'expiredCount': expiredItems.length,
            'productNames': productNames,
          },
        );
      }

      // Send notification for medicines expiring soon
      if (expiringSoonItems.isNotEmpty) {
        final productNames = expiringSoonItems.map((item) => item.productName).join(', ');
        await NotificationService.notifyCustomer(
          customerId: customerId,
          title: 'Medicines expiring soon',
          body: 'The following medicines will expire within 7 days: $productNames. Please use them soon.',
          type: 'medicine_expiring_soon',
          data: {
            'expiringCount': expiringSoonItems.length,
            'productNames': productNames,
          },
        );
      }

      // Update last check date
      await lastNotificationRef.set(now.toIso8601String());
    } catch (e) {
      debugPrint('Error checking expired medicines: $e');
    }
  }

  Future<void> _markAsFinished(_ExpiryInfo item) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(loc.confirmCompletion)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.finishedMedicineQuestion,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medication, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.productName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.willBeRemoved,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check, size: 18),
            label: Text(loc.yesDone),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Add to finished medicines list
      await DatabaseService.instance
          .ref('finished_medicines/${user.uid}')
          .push()
          .set({
        'productName': item.productName,
        'quantity': item.quantity,
        'expiryDate': item.expiryDate.toIso8601String(),
        'finishedAt': DateTime.now().toIso8601String(),
        'orderId': item.orderId,
        'productId': item.productId,
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(loc.removedFromList(item.productName))),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        // Reload data
        _loadData();
      }
    }
  }

  Future<List<_ExpiryInfo>> _loadPharmacistInventory(
      String pharmacistId) async {
    final snapshot =
        await DatabaseService.instance.ref('products/$pharmacistId').get();
    if (!snapshot.exists) return [];

    final items = <_ExpiryInfo>[];
    final raw = snapshot.value;
    Iterable<MapEntry<dynamic, dynamic>> entries;

    if (raw is Map) {
      entries = Map<dynamic, dynamic>.from(raw).entries;
    } else if (raw is List) {
      entries = raw.asMap().entries;
    } else {
      return items;
    }

    for (final entry in entries) {
      final value = entry.value;
      if (value is! Map) continue;
      final product = Map<dynamic, dynamic>.from(value);

      final expiryRaw = product['expiryDate']?.toString() ?? '';
      if (expiryRaw.isEmpty) continue;

      final expiry = DateTime.tryParse(expiryRaw);
      if (expiry == null) continue;

      DateTime? createdAt;
      final createdRaw = product['createdAt'];
      if (createdRaw is num) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(createdRaw.toInt());
      } else {
        createdAt = DateTime.tryParse(createdRaw?.toString() ?? '');
      }

      final quantityValue = product['quantity'];
      final quantity = quantityValue is num
          ? quantityValue.toInt()
          : int.tryParse(quantityValue?.toString() ?? '0') ?? 0;

      final daysRemaining = expiry.difference(DateTime.now()).inDays;
      items.add(
        _ExpiryInfo(
          productName: product['name']?.toString() ?? 'Product',
          quantity: quantity,
          orderDate: createdAt,
          expiryDate: expiry,
          daysRemaining: daysRemaining,
        ),
      );
    }

    items.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return items;
  }

  Future<List<_ExpiryInfo>> _loadCustomerOrders(String customerId) async {
    // Load finished medicines to exclude them
    final finishedSnapshot = await DatabaseService.instance
        .ref('finished_medicines/$customerId')
        .get();
    
    final finishedSet = <String>{};
    if (finishedSnapshot.exists && finishedSnapshot.value is Map) {
      final finishedMap = Map<dynamic, dynamic>.from(finishedSnapshot.value as Map);
      for (final entry in finishedMap.values) {
        if (entry is Map) {
          final orderId = entry['orderId']?.toString() ?? '';
          final productId = entry['productId']?.toString() ?? '';
          if (orderId.isNotEmpty && productId.isNotEmpty) {
            finishedSet.add('$orderId-$productId');
          }
        }
      }
    }

    final snapshot =
        await DatabaseService.instance.ref('customer_orders/$customerId').get();
    if (!snapshot.exists) return [];

    final raw = snapshot.value;
    if (raw is! Map) return [];
    final root = Map<dynamic, dynamic>.from(raw);
    final items = <_ExpiryInfo>[];

    for (final orderEntry in root.entries) {
      final orderId = orderEntry.key.toString();
      final orderMap = Map<dynamic, dynamic>.from(orderEntry.value as Map);
      final orderDate =
          DateTime.tryParse(orderMap['createdAt']?.toString() ?? '');
      final itemsMap = orderMap['items'] as Map<dynamic, dynamic>?;

      if (itemsMap == null) continue;

      for (final productEntry in itemsMap.entries) {
        final productId = productEntry.key.toString();
        
        // Skip if already marked as finished
        if (finishedSet.contains('$orderId-$productId')) continue;
        
        final product = Map<dynamic, dynamic>.from(productEntry.value as Map);
        DateTime? expiry =
            DateTime.tryParse(product['expiryDate']?.toString() ?? '');

        if (expiry == null) {
          final ownerId = product['ownerId']?.toString() ?? '';
          if (ownerId.isNotEmpty && productId.isNotEmpty) {
            final expirySnapshot = await DatabaseService.instance
                .pharmacistProductsRef(ownerId)
                .child(productId)
                .child('expiryDate')
                .get();
            final fetched = expirySnapshot.value?.toString();
            if (fetched != null && fetched.isNotEmpty) {
              expiry = DateTime.tryParse(fetched);
            }
          }
        }
        if (expiry == null) continue;

        final daysRemaining = expiry.difference(DateTime.now()).inDays;
        items.add(
          _ExpiryInfo(
            productName: product['name']?.toString() ?? 'Product',
            quantity: int.tryParse(product['quantity']?.toString() ?? '1') ?? 1,
            orderDate: orderDate,
            expiryDate: expiry,
            daysRemaining: daysRemaining,
            orderId: orderId,
            productId: productId,
          ),
        );
      }
    }

    items.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
    return items;
  }

  Color _statusColor(int days) {
    if (days < 0) return Colors.red;
    if (days <= 7) return Colors.orange;
    return Colors.green;
  }

  String _statusLabel(int days, DateTime expiryDate, AppLocalizations loc) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(expiryDate);

    if (days < 0) {
      return loc.isArabic 
          ? 'انتهت الصلاحية في $formattedDate' 
          : 'Expired on $formattedDate';
    }
    if (days == 0) {
      return loc.isArabic 
          ? '${loc.expiresToday} ($formattedDate)' 
          : 'Expires today ($formattedDate)';
    }
    if (days == 1) {
      return loc.isArabic 
          ? '${loc.expiresTomorrow} ($formattedDate)' 
          : 'Expires tomorrow ($formattedDate)';
    }
    return loc.isArabic 
        ? 'تنتهي خلال $days يوم ($formattedDate)' 
        : 'Expires in $days days ($formattedDate)';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.expiryTracker),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: loc.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(loc.loading),
              ],
            ))
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        loc.noExpiryData,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final color = _statusColor(item.daysRemaining);
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.medication_liquid, color: color, size: 36),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${loc.quantity}: ${item.quantity}'),
                                  if (item.orderDate != null)
                                    Text(
                                      '${loc.purchasedOn}: ${DateFormat('yyyy-MM-dd').format(item.orderDate!)}',
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _statusLabel(item.daysRemaining, item.expiryDate, loc),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  // Button for customers to mark as finished
                                  if (_isCustomer) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _markAsFinished(item),
                                        icon: const Icon(Icons.check_circle_outline, size: 18),
                                        label: Text(loc.markAsFinished),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.green,
                                          side: const BorderSide(color: Colors.green),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _ExpiryInfo {
  _ExpiryInfo({
    required this.productName,
    required this.quantity,
    required this.orderDate,
    required this.expiryDate,
    required this.daysRemaining,
    this.orderId,
    this.productId,
  });

  final String productName;
  final int quantity;
  final DateTime? orderDate;
  final DateTime expiryDate;
  final int daysRemaining;
  final String? orderId;
  final String? productId;
}
