import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.showNotes = true,
  });

  final CustomerOrder order;
  final VoidCallback? onTap;
  final bool showNotes;

  Color _statusColor(BuildContext context) {
    switch (order.status) {
      case OrderStatus.awaitingConfirmation:
        return Colors.orange;
      case OrderStatus.processing:
        return Theme.of(context).colorScheme.primary;
      case OrderStatus.readyForPickup:
        return Colors.teal;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _statusLabel() {
    final raw = orderStatusToString(order.status).replaceAll('_', ' ');
    return raw
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ${order.id.substring(0, 6).toUpperCase()}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Placed on ${DateFormat.yMMMd().format(order.createdAt)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          order.pharmacyName,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Chip(
                          backgroundColor: Colors.blue,
                          label: Text(
                            _statusLabel(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.shopping_basket_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${order.items.length} item(s)',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.payments_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${order.total.toStringAsFixed(2)} OMR',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (showNotes && (order.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Notes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(order.notes!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
