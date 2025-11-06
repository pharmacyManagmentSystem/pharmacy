import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'services/database_service.dart';

class PharmacistPrescriptionsPage extends StatelessWidget {
  const PharmacistPrescriptionsPage({super.key, required this.pharmacyId});

  final String pharmacyId;

  @override
  Widget build(BuildContext context) {
    final ref = DatabaseService.instance.pendingPrescriptionsRef(pharmacyId);
    return Scaffold(
      appBar: AppBar(title: const Text('Prescription uploads')),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Unable to load pending prescriptions.'));
          }

          final raw = snapshot.data?.snapshot.value;
          if (raw == null) {
            return const Center(
                child: Text('No prescriptions waiting for review.'));
          }

          final items = <MapEntry<String, Map<dynamic, dynamic>>>[];
          if (raw is Map) {
            raw.forEach((k, v) {
              if (v is Map)
                items
                    .add(MapEntry(k.toString(), Map<dynamic, dynamic>.from(v)));
            });
          }

          if (items.isEmpty)
            return const Center(
                child: Text('No prescriptions waiting for review.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final entry = items[index];
              final id = entry.key;
              final data = entry.value;
              final productName = data['name']?.toString() ??
                  data['productName']?.toString() ??
                  'Product';
              final customer = data['customerId']?.toString() ??
                  data['customerName']?.toString() ??
                  'Customer';
              final qty = data['quantity']?.toString() ?? '1';
              final url = data['imageUrl']?.toString() ??
                  data['prescriptionUrl']?.toString() ??
                  '';
              final createdAt = data['createdAt']?.toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade100,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildImageWidget(url),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    productName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: Colors.orange.shade200),
                                  ),
                                  child: const Text(
                                    'Pending',
                                    style: TextStyle(
                                        color: Colors.orange, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Customer: $customer',
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Quantity: $qty',
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                createdAt,
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.black45),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                SizedBox(
                                  height: 28,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _approve(context, id, data),
                                    icon: const Icon(Icons.check, size: 14),
                                    label: const Text('Approve',
                                        style: TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                SizedBox(
                                  height: 28,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _reject(context, id, data),
                                    icon: const Icon(Icons.close,
                                        size: 14, color: Colors.red),
                                    label: const Text('Reject',
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.red)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                SizedBox(
                                  height: 28,
                                  child: TextButton(
                                    onPressed: () => _showPreview(context, url),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6),
                                      minimumSize: Size.zero,
                                    ),
                                    child: const Text('View',
                                        style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                              ],
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

  Widget _buildImageWidget(String url) {
    if (url.isEmpty) {
      return const Icon(Icons.description_outlined, size: 40);
    }

    if (url.startsWith('data:')) {
      return Builder(builder: (_) {
        try {
          final parts = url.split(',');
          final base64Data = parts.length > 1 ? parts[1] : '';
          final bytes = base64Decode(base64Data);
          return Image.memory(bytes, fit: BoxFit.cover);
        } catch (_) {
          return const Icon(Icons.broken_image);
        }
      });
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
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
                child: const Text('Close')),
          ],
        );
      },
    );
  }

  Future<void> _approve(
      BuildContext context, String id, Map<dynamic, dynamic> data) async {
    final customerId = data['customerId']?.toString();
    final pharmacyId = data['ownerId']?.toString() ?? '';
    try {
      if (customerId != null && customerId.isNotEmpty) {
        final customerCartRef =
            DatabaseService.instance.customerCartRef(customerId).child(id);

        final snapshot = await customerCartRef.get();
        if (!snapshot.exists) {
          throw Exception('Cart item no longer exists');
        }

        await customerCartRef.update({
          'pendingApproval': false,
          'approved': true,
          'approvedAt': DateTime.now().toIso8601String(),
          'status': 'approved'
        });

        final notifRef = DatabaseService.instance
            .customerNotificationsRef(customerId)
            .push();
        await notifRef.set({
          'title': 'Prescription approved',
          'body':
              'Your prescription for "${data['name'] ?? data['productName']}" was approved. You may complete payment.',
          'requestId': id,
          'createdAt': DateTime.now().toIso8601String(),
          'read': false,
        });
      }

      await DatabaseService.instance
          .pendingPrescriptionsRef(pharmacyId)
          .child(id)
          .remove();

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Approved')));
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to approve: $e')));
    }
  }

  Future<void> _reject(
      BuildContext context, String id, Map<dynamic, dynamic> data) async {
    final customerId = data['customerId']?.toString();
    final pharmacyId = data['ownerId']?.toString() ?? '';
    try {
      if (customerId != null && customerId.isNotEmpty) {
        await DatabaseService.instance
            .customerCartRef(customerId)
            .child(id)
            .update({
          'pendingApproval': false,
          'rejected': true,
          'rejectedAt': DateTime.now().toIso8601String(),
        });

        final notifRef = DatabaseService.instance
            .customerNotificationsRef(customerId)
            .push();
        await notifRef.set({
          'title': 'Prescription rejected',
          'body':
              'Your prescription for "${data['name'] ?? data['productName']}" was rejected by the pharmacy.',
          'requestId': id,
          'createdAt': DateTime.now().toIso8601String(),
          'read': false,
        });
      }

      await DatabaseService.instance
          .pendingPrescriptionsRef(pharmacyId)
          .child(id)
          .remove();

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Rejected')));
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to reject: $e')));
    }
  }
}
