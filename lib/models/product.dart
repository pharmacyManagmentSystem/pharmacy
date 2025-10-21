class Product {
  const Product({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.requiresPrescription,
    this.expiryDate,
  });

  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String category;
  final double price;
  final int quantity;
  final String imageUrl;
  final bool requiresPrescription;
  final DateTime? expiryDate;

  factory Product.fromMap({
    required String id,
    required String ownerId,
    required Map<dynamic, dynamic> data,
  }) {
    final priceRaw = data['price'];
    final quantityRaw = data['quantity'];
    return Product(
      id: id,
      ownerId: ownerId,
      name: (data['name'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      category: (data['category'] ?? 'Other') as String,
      price: priceRaw is num
          ? priceRaw.toDouble()
          : double.tryParse(priceRaw?.toString() ?? '') ?? 0,
      quantity: quantityRaw is num
          ? quantityRaw.toInt()
          : int.tryParse(quantityRaw?.toString() ?? '') ?? 0,
      imageUrl: (data['imageUrl'] ?? '') as String,
      requiresPrescription:
          (data['requiresPrescription'] ?? false) as bool,
      expiryDate: data['expiryDate'] != null && data['expiryDate'].toString().isNotEmpty
          ? DateTime.tryParse(data['expiryDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toCartJson({int quantity = 1, String? prescriptionUrl}) {
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
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }
}

