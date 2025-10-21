import 'package:firebase_auth/firebase_auth.dart';
import 'services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpiryTrackerPage extends StatelessWidget {
  const ExpiryTrackerPage({super.key});

  Future<List<_ExpiryInfo>> _loadExpiryItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // تحديد إذا كان المستخدم صيدلي أو عميل
    final pharmacistSnapshot = await DatabaseService.instance.ref('pharmacy/pharmacists/${user.uid}')
        .get();

    if (pharmacistSnapshot.exists) {
      return _loadPharmacistInventory(user.uid);
    }

    return _loadCustomerOrders(user.uid);
  }

  Future<List<_ExpiryInfo>> _loadPharmacistInventory(String pharmacistId) async {
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
    final snapshot =
    await DatabaseService.instance.ref('customer_orders/$customerId').get();
    if (!snapshot.exists) return [];

    final raw = snapshot.value;
    if (raw is! Map) return [];
    final root = Map<dynamic, dynamic>.from(raw);
    final items = <_ExpiryInfo>[];

    for (final orderEntry in root.entries) {
      final orderMap = Map<dynamic, dynamic>.from(orderEntry.value as Map);
      final orderDate = DateTime.tryParse(orderMap['createdAt']?.toString() ?? '');
      final itemsMap = orderMap['items'] as Map<dynamic, dynamic>?;

      if (itemsMap == null) continue;

      for (final productEntry in itemsMap.entries) {
        final product = Map<dynamic, dynamic>.from(productEntry.value as Map);
        DateTime? expiry = DateTime.tryParse(product['expiryDate']?.toString() ?? '');
        if (expiry == null) {
          final ownerId = product['ownerId']?.toString() ?? '';
          final productId = productEntry.key.toString();
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

  String _statusLabel(int days, DateTime expiryDate) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(expiryDate);

    if (days < 0) return 'Expired on $formattedDate';
    if (days == 0) return 'Expires today ($formattedDate)';
    if (days == 1) return 'Expires tomorrow ($formattedDate)';
    return 'Expires in $days days ($formattedDate)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expiry tracker')),
      body: FutureBuilder<List<_ExpiryInfo>>(
        future: _loadExpiryItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load expiry data.'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text('No products with expiry information found.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final color = _statusColor(item.daysRemaining);
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            Text('Quantity: ${item.quantity}'),
                            if (item.orderDate != null)
                              Text(
                                'Purchased on: ${DateFormat('yyyy-MM-dd').format(item.orderDate!)}',
                              ),
                            const SizedBox(height: 4),
                            Text(
                              _statusLabel(item.daysRemaining, item.expiryDate),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
  });

  final String productName;
  final int quantity;
  final DateTime? orderDate;
  final DateTime expiryDate;
  final int daysRemaining;
}

