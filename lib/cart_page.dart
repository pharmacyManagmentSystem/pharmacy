import 'package:flutter/material.dart';
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
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: hasItems
                    ? ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                backgroundImage: item.product.imageUrl.isNotEmpty
                                    ? NetworkImage(item.product.imageUrl)
                                    : null,
                                child: item.product.imageUrl.isEmpty
                                    ? const Icon(Icons.medication_outlined)
                                    : null,
                              ),
                              title: Text(item.product.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${item.product.price.toStringAsFixed(2)} OMR'),
                                  if (item.prescriptionUrl != null)
                                    const Text(
                                      'Prescription attached',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                      ),
                                      Text('${item.quantity}'),
                                      IconButton(
                                        onPressed: () => state.updateQuantity(
                                          item.product.id,
                                          item.quantity + 1,
                                        ),
                                        icon: const Icon(Icons.add_circle_outline),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () => state.removeItem(item.product.id),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Text('Your cart is empty. Start adding medicines to continue.'),
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${state.cartTotal.toStringAsFixed(2)} OMR',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
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
                  child: const Text('Checkout'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
