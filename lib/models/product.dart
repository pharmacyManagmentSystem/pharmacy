import 'batch.dart';

class Product {
  const Product({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.requiresPrescription,
    this.batches,
    // Legacy support - keep for backward compatibility
    this.quantity,
    this.expiryDate,
  });

  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String category;
  final double price;
  final String imageUrl;
  final bool requiresPrescription;
  final List<ProductBatch>? batches;

  // Legacy fields - for backward compatibility
  @Deprecated('Use batches instead. Total quantity is sum of batch quantities.')
  final int? quantity;
  @Deprecated('Use batches instead. Products can have multiple expiry dates.')
  final DateTime? expiryDate;

  // Computed total quantity from batches
  int get totalQuantity {
    if (batches != null && batches!.isNotEmpty) {
      return batches!.fold(0, (sum, batch) => sum + batch.quantity);
    }
    return quantity ?? 0;
  }

  // Check if product has any non-expired batches
  bool get hasNonExpiredBatches {
    final now = DateTime.now();
    if (batches != null && batches!.isNotEmpty) {
      // Check if at least one batch is not expired
      return batches!.any((batch) => batch.expiryDate.isAfter(now));
    }
    // Legacy: check expiryDate if batches don't exist
    if (expiryDate != null) {
      return expiryDate!.isAfter(now);
    }
    // If no expiry date, consider it as non-expired
    return true;
  }

  factory Product.fromMap({
    required String id,
    required String ownerId,
    required Map<dynamic, dynamic> data,
  }) {
    final priceRaw = data['price'];
    final quantityRaw = data['quantity'];

    // Parse batches if they exist
    List<ProductBatch>? batches;
    if (data['batches'] != null && data['batches'] is Map) {
      final batchesMap = data['batches'] as Map;
      batches = batchesMap.entries.map((entry) {
        return ProductBatch.fromMap(
          id: entry.key.toString(),
          data: Map<dynamic, dynamic>.from(entry.value as Map),
        );
      }).toList();
      // Sort batches by expiry date (earliest first)
      batches.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    }

    return Product(
      id: id,
      ownerId: ownerId,
      name: (data['name'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      category: (data['category'] ?? 'Other') as String,
      price: priceRaw is num
          ? priceRaw.toDouble()
          : double.tryParse(priceRaw?.toString() ?? '') ?? 0,
      imageUrl: (data['imageUrl'] ?? '') as String,
      requiresPrescription: (data['requiresPrescription'] ?? false) as bool,
      batches: batches,
      // Legacy support
      quantity: quantityRaw is num
          ? quantityRaw.toInt()
          : int.tryParse(quantityRaw?.toString() ?? '') ?? 0,
      expiryDate:
          data['expiryDate'] != null && data['expiryDate'].toString().isNotEmpty
              ? DateTime.tryParse(data['expiryDate'].toString())
              : null,
    );
  }

  Map<String, dynamic> toCartJson(
      {int quantity = 1, String? prescriptionUrl, String? batchId}) {
    // Get expiry date from the first batch (earliest expiry) or use legacy expiryDate
    DateTime? expiryDateToUse;
    if (batches != null && batches!.isNotEmpty) {
      expiryDateToUse = batches!.first.expiryDate;
    } else {
      expiryDateToUse = expiryDate;
    }

    return {
      'productId': id,
      'ownerId': ownerId,
      'name': name,
      'category': category,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'requiresPrescription': requiresPrescription,
      'prescriptionUrl': prescriptionUrl,
      'expiryDate': expiryDateToUse?.toIso8601String(),
      'batchId': batchId,
    };
  }

  Map<String, dynamic> toJson() {
    final json = {
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'requiresPrescription': requiresPrescription,
      'ownerId': ownerId,
      'quantity': totalQuantity, // Computed total for backward compatibility
      'status': totalQuantity > 0 ? 'in_stock' : 'out_of_stock',
    };

    // Add batches if they exist
    if (batches != null && batches!.isNotEmpty) {
      final batchesMap = <String, dynamic>{};
      for (final batch in batches!) {
        batchesMap[batch.id] = batch.toMap();
      }
      json['batches'] = batchesMap;
    } else if (expiryDate != null) {
      // Legacy: create a batch from old expiryDate and quantity
      json['expiryDate'] = expiryDate!.toIso8601String();
    }

    return json;
  }
}
