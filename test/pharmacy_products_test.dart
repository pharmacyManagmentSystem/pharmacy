import 'package:flutter_test/flutter_test.dart';

class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final bool expiringSoon;
  final int quantity;
  final bool expired;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.quantity,
    this.expiringSoon = false,
    this.expired = false,
  });
}

class PharmacyProductsManager {
  final List<Product> _products = [];

  List<Product> getAllProducts() => _products;

  void addProduct(Product product) {
    _products.add(product);
  }

  List<Product> searchProducts(String query) {
    if (query.trim().isEmpty) return _products;
    final lower = query.toLowerCase();
    return _products
        .where((p) => p.name.toLowerCase().contains(lower))
        .toList();
  }

  List<Product> filterByCategory(String category) {
    if (category == 'All') return _products;
    return _products.where((p) => p.category == category).toList();
  }

  List<Product> availableProducts() {
    return _products
        .where((p) => p.quantity > 0 && !p.expired)
        .toList();
  }

  List<Product> expiringSoonProducts() {
    return _products.where((p) => p.expiringSoon && !p.expired).toList();
  }

  List<Product> aiRecommendedProducts(List<String> previouslyBoughtIds) {
    return _products
        .where((p) =>
    previouslyBoughtIds.contains(p.id) &&
        p.quantity > 0 &&
        !p.expired)
        .take(5)
        .toList();
  }
}

void main() {
  group('PharmacyProductsManager', () {
    late PharmacyProductsManager manager;

    setUp(() {
      manager = PharmacyProductsManager();
      manager.addProduct(Product(
          id: '1',
          name: 'Aspirin',
          category: 'Pain Relief',
          price: 2.5,
          quantity: 10));
      manager.addProduct(Product(
          id: '2',
          name: 'Vitamin C',
          category: 'Vitamins',
          price: 1.5,
          quantity: 5,
          expiringSoon: true));
      manager.addProduct(Product(
          id: '3',
          name: 'Expired Drug',
          category: 'Pain Relief',
          price: 3.0,
          quantity: 8,
          expired: true));
    });

    test('should add products successfully', () {
      expect(manager.getAllProducts().length, 3);
      expect(manager.getAllProducts().first.name, 'Aspirin');
    });

    test('should search products by name', () {
      final results = manager.searchProducts('vitamin');
      expect(results.length, 1);
      expect(results.first.name, 'Vitamin C');
    });

    test('should return all products if search query is empty', () {
      final results = manager.searchProducts('');
      expect(results.length, 3);
    });

    test('should filter products by category', () {
      final results = manager.filterByCategory('Pain Relief');
      expect(results.length, 2); // includes Aspirin and Expired Drug
    });

    test('should filter available (non-expired) products only', () {
      final results = manager.availableProducts();
      expect(results.length, 2); // excludes Expired Drug
      expect(results.every((p) => !p.expired), true);
    });

    test('should get expiring soon products', () {
      final results = manager.expiringSoonProducts();
      expect(results.length, 1);
      expect(results.first.name, 'Vitamin C');
    });

    test('should recommend products based on AI previous purchases', () {
      final recommended = manager.aiRecommendedProducts(['1', '3']);
      // ID 3 is expired, so only ID 1 should appear
      expect(recommended.length, 1);
      expect(recommended.first.name, 'Aspirin');
    });
  });
}
