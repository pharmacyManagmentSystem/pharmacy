import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Authentication to get current logged-in user
import 'services/database_service.dart'; // Import custom database service for reading Firebase Realtime Database
import 'package:flutter/material.dart'; // Import Flutter material widgets for UI
import 'package:intl/intl.dart'; // Import intl package for formatting dates

// Stateless widget for tracking product expiry dates
class ExpiryTrackerPage extends StatelessWidget {
  const ExpiryTrackerPage({super.key}); // Constructor with optional key for widget tree

  // Method to load all expiry items for the current user
  Future<List<_ExpiryInfo>> _loadExpiryItems() async {
    final user = FirebaseAuth.instance.currentUser; // Get the currently logged-in Firebase user
    if (user == null) return []; // If no user is logged in, return empty list

    // Check if the user is a pharmacist by looking up in 'pharmacy/pharmacists' node
    final pharmacistSnapshot = await DatabaseService.instance.ref('pharmacy/pharmacists/${user.uid}').get();

    if (pharmacistSnapshot.exists) { // If snapshot exists, user is a pharmacist
      return _loadPharmacistInventory(user.uid); // Load pharmacist inventory
    }

    return _loadCustomerOrders(user.uid); // Otherwise, load customer orders
  }

  // Load expiry info for pharmacist products
  Future<List<_ExpiryInfo>> _loadPharmacistInventory(String pharmacistId) async {
    final snapshot = await DatabaseService.instance.ref('products/$pharmacistId').get(); // Get pharmacist's products
    if (!snapshot.exists) return []; // Return empty if no products

    final items = <_ExpiryInfo>[]; // Initialize list to hold expiry info
    final raw = snapshot.value; // Raw data from Firebase
    Iterable<MapEntry<dynamic, dynamic>> entries;

    if (raw is Map) { // If data is a Map
      entries = Map<dynamic, dynamic>.from(raw).entries; // Convert to MapEntry iterable
    } else if (raw is List) { // If data is a List
      entries = raw.asMap().entries; // Convert list to MapEntry iterable
    } else {
      return items; // If data is neither Map nor List, return empty list
    }

    for (final entry in entries) { // Iterate through each product entry
      final value = entry.value;
      if (value is! Map) continue; // Skip if entry is not a Map
      final product = Map<dynamic, dynamic>.from(value); // Convert to Map

      final expiryRaw = product['expiryDate']?.toString() ?? ''; // Get expiry date string
      if (expiryRaw.isEmpty) continue; // Skip if expiry date is empty

      final expiry = DateTime.tryParse(expiryRaw); // Parse expiry date
      if (expiry == null) continue; // Skip if parsing fails

      DateTime? createdAt; // Initialize createdAt variable
      final createdRaw = product['createdAt']; // Get createdAt from product
      if (createdRaw is num) { // If createdAt is a timestamp
        createdAt = DateTime.fromMillisecondsSinceEpoch(createdRaw.toInt()); // Convert to DateTime
      } else {
        createdAt = DateTime.tryParse(createdRaw?.toString() ?? ''); // Otherwise, try parsing as string
      }

      final quantityValue = product['quantity']; // Get quantity value
      final quantity = quantityValue is num // Convert to integer
          ? quantityValue.toInt()
          : int.tryParse(quantityValue?.toString() ?? '0') ?? 0;

      final daysRemaining = expiry.difference(DateTime.now()).inDays; // Calculate days left until expiry
      items.add( // Add product info to items list
        _ExpiryInfo(
          productName: product['name']?.toString() ?? 'Product', // Product name
          quantity: quantity, // Quantity
          orderDate: createdAt, // Created/purchase date
          expiryDate: expiry, // Expiry date
          daysRemaining: daysRemaining, // Days remaining
        ),
      );
    }

    items.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining)); // Sort items by days remaining
    return items; // Return list
  }

  // Load expiry info for customer orders
  Future<List<_ExpiryInfo>> _loadCustomerOrders(String customerId) async {
    final snapshot = await DatabaseService.instance.ref('customer_orders/$customerId').get(); // Get customer orders
    if (!snapshot.exists) return []; // Return empty if no orders

    final raw = snapshot.value;
    if (raw is! Map) return []; // Ensure root is a Map
    final root = Map<dynamic, dynamic>.from(raw);
    final items = <_ExpiryInfo>[]; // Initialize list

    for (final orderEntry in root.entries) { // Iterate through each order
      final orderMap = Map<dynamic, dynamic>.from(orderEntry.value as Map); // Get order data
      final orderDate = DateTime.tryParse(orderMap['createdAt']?.toString() ?? ''); // Parse order date
      final itemsMap = orderMap['items'] as Map<dynamic, dynamic>?; // Get products in order

      if (itemsMap == null) continue; // Skip if no items

      for (final productEntry in itemsMap.entries) { // Iterate each product
        final product = Map<dynamic, dynamic>.from(productEntry.value as Map);
        DateTime? expiry = DateTime.tryParse(product['expiryDate']?.toString() ?? ''); // Parse expiry date

        if (expiry == null) { // If expiry missing, fetch from pharmacist
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
              expiry = DateTime.tryParse(fetched); // Parse fetched expiry
            }
          }
        }
        if (expiry == null) continue; // Skip if still null

        final daysRemaining = expiry.difference(DateTime.now()).inDays; // Calculate days remaining
        items.add(
          _ExpiryInfo(
            productName: product['name']?.toString() ?? 'Product',
            quantity: int.tryParse(product['quantity']?.toString() ?? '1') ?? 1, // Default quantity to 1
            orderDate: orderDate,
            expiryDate: expiry,
            daysRemaining: daysRemaining,
          ),
        );
      }
    }

    items.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining)); // Sort by days remaining
    return items;
  }

  // Determine color based on expiry days
  Color _statusColor(int days) {
    if (days < 0) return Colors.red; // Expired
    if (days <= 7) return Colors.orange; // Less than a week left
    return Colors.green; // Safe
  }

  // Generate human-readable label for expiry status
  String _statusLabel(int days, DateTime expiryDate) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(expiryDate); // Format date

    if (days < 0) return 'Expired on $formattedDate'; // Expired
    if (days == 0) return 'Expires today ($formattedDate)'; // Today
    if (days == 1) return 'Expires tomorrow ($formattedDate)'; // Tomorrow
    return 'Expires in $days days ($formattedDate)'; // Future
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expiry tracker')), // AppBar title
      body: FutureBuilder<List<_ExpiryInfo>>( // FutureBuilder for async data
        future: _loadExpiryItems(), // Load expiry items
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) { // Show loader while waiting
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) { // Show error message
            return const Center(child: Text('Unable to load expiry data.'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) { // Show empty state
            return const Center(
              child: Text('No products with expiry information found.'),
            );
          }

          return ListView.separated( // List view for all expiry items
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12), // Spacing between cards
            itemBuilder: (context, index) {
              final item = items[index];
              final color = _statusColor(item.daysRemaining); // Get color based on status
              return Card( // Card for each item
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.medication_liquid, color: color, size: 36), // Icon with color
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text( // Product name
                              item.productName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Quantity: ${item.quantity}'), // Quantity
                            if (item.orderDate != null) // Purchase date if exists
                              Text(
                                'Purchased on: ${DateFormat('yyyy-MM-dd').format(item.orderDate!)}',
                              ),
                            const SizedBox(height: 4),
                            Text( // Expiry status label
                              _statusLabel(item.daysRemaining, item.expiryDate),
                              style: TextStyle(
                                color: color, // Color based on status
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

// Class to hold expiry information for each product/order
class _ExpiryInfo {
  _ExpiryInfo({
    required this.productName, // Name of the product
    required this.quantity, // Quantity
    required this.orderDate, // Order/purchase date
    required this.expiryDate, // Expiry date
    required this.daysRemaining, // Days left until expiry
  });

  final String productName;
  final int quantity;
  final DateTime? orderDate;
  final DateTime expiryDate;
  final int daysRemaining;
}
