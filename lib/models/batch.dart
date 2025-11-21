class ProductBatch {
  const ProductBatch({
    required this.id,
    required this.expiryDate,
    required this.quantity,
  });

  final String id;
  final DateTime expiryDate;
  final int quantity;

  factory ProductBatch.fromMap({
    required String id,
    required Map<dynamic, dynamic> data,
  }) {
    final expiryDateStr = data['expiryDate']?.toString();
    final expiryDate = expiryDateStr != null && expiryDateStr.isNotEmpty
        ? DateTime.tryParse(expiryDateStr) ?? DateTime.now()
        : DateTime.now();

    final quantityRaw = data['quantity'];
    final quantity = quantityRaw is num
        ? quantityRaw.toInt()
        : int.tryParse(quantityRaw?.toString() ?? '0') ?? 0;

    return ProductBatch(
      id: id,
      expiryDate: expiryDate,
      quantity: quantity,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expiryDate': expiryDate.toIso8601String(),
      'quantity': quantity,
    };
  }

  ProductBatch copyWith({
    String? id,
    DateTime? expiryDate,
    int? quantity,
  }) {
    return ProductBatch(
      id: id ?? this.id,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
    );
  }
}
