import 'package:flutter/material.dart';
import 'dart:convert';
import 'services/database_service.dart';
import 'models/cart_item.dart';
import 'models/order.dart';

class PharmacistPrescriptionsPage extends StatelessWidget {
  const PharmacistPrescriptionsPage({super.key, required this.pharmacyId});

  final String pharmacyId;

  Stream<List<CustomerOrder>> _ordersStream() {
    return DatabaseService.instance
        .pharmacyOrdersRef(pharmacyId)
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      if (data is! Map) return <CustomerOrder>[];
      return data.entries
          .map<CustomerOrder>((entry) => CustomerOrder.fromMap(
                entry.key.toString(),
                Map<dynamic, dynamic>.from(entry.value as Map),
              ))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prescription uploads')),
      body: StreamBuilder<List<CustomerOrder>>(
        stream: _ordersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load orders.'));
          }

          final orders = snapshot.data ?? <CustomerOrder>[];
          final entries = <_PrescriptionEntry>[];
          for (final order in orders) {
            for (final item in order.items) {
              final url = item.prescriptionUrl;
              if (item.product.requiresPrescription && url != null && url.isNotEmpty) {
                entries.add(_PrescriptionEntry(order: order, item: item));
              }
            }
          }

          if (entries.isEmpty) {
            return const Center(child: Text('No prescriptions waiting for review.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final order = entry.order;
              final item = entry.item;
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(item.product.name),
                  subtitle: Text(
                    'Order #${order.id.substring(0, 6).toUpperCase()}\n'
                    'Customer: ${order.customerName}\n'
                    'Quantity: ${item.quantity}',
                  ),
                  trailing: const Icon(Icons.visibility_outlined),
                  onTap: () => _showPreview(context, item.prescriptionUrl!),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPreview(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Prescription'),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: url.startsWith('data:')
                ? Builder(builder: (_) {
                    try {
                      final parts = url.split(',');
                      final base64Data = parts.length > 1 ? parts[1] : '';
                      final bytes = base64Decode(base64Data);
                      return Image.memory(bytes, fit: BoxFit.contain);
                    } catch (_) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: Text('Unable to load image.')),
                      );
                    }
                  })
                : Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 200,
                      child: Center(child: Text('Unable to load image.')),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _PrescriptionEntry {
  const _PrescriptionEntry({required this.order, required this.item});

  final CustomerOrder order;
  final CartItem item;
}
