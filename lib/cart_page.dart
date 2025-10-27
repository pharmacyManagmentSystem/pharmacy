import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'state/customer_app_state.dart';
import 'location_capture_page.dart';

class CustomerCartPage extends StatelessWidget {
  const CustomerCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerAppState>(
      builder: (context, state, _) {
        final items = state.cartItems;
        final hasItems = items.isNotEmpty;
        final pharmacyId = state.currentPharmacyId ?? '';
        final pharmacyName = state.currentPharmacyName ?? '';

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Cart items section
                Expanded(
                  child: hasItems
                      ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // Product image thumbnail (rounded rectangle)
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: item.product.imageUrl.isNotEmpty
                                      ? (item.product.imageUrl.startsWith('data:')
                                          ? Builder(builder: (context) {
                                              try {
                                                final parts = item.product.imageUrl.split(',');
                                                final base64Data = parts.length > 1 ? parts[1] : '';
                                                final bytes = base64Decode(base64Data);
                                                return Image.memory(bytes, fit: BoxFit.cover);
                                              } catch (_) {
                                                return const Icon(Icons.broken_image);
                                              }
                                            })
                                          : Image.network(
                                              item.product.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                            ))
                                      : const Center(child: Icon(Icons.medication_outlined)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Product details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.product.price.toStringAsFixed(2)} OMR',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (item.prescriptionUrl != null)
                                      const Text(
                                        'Prescription attached',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Quantity controls
                              Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => state.updateQuantity(
                                          item.product.id,
                                          item.quantity - 1,
                                        ),
                                        icon: const Icon(Icons.remove_circle_outline),
                                        iconSize: 20,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${item.quantity}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => state.updateQuantity(
                                          item.product.id,
                                          item.quantity + 1,
                                        ),
                                        icon: const Icon(Icons.add_circle_outline),
                                        iconSize: 20,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.red),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: GestureDetector(
                                      onTap: () => state.removeItem(item.product.id),
                                      child: const Text(
                                        'Remove',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                      : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Your cart is empty',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start adding medicines to continue',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom section with total and checkout
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: Colors.lightBlue,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${state.cartTotal.toStringAsFixed(2)} OMR',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: hasItems
                              ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LocationCapturePage(
                                  pharmacyId: pharmacyId,
                                  pharmacyName: pharmacyName,
                                ),
                              ),
                            );
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasItems ? Colors.blue : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Checkout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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
  }
}