import 'package:flutter_test/flutter_test.dart';

class Product {
  String id;
  String name;
  String category;
  double price;
  int quantity;
  String expiryDate;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.quantity,
    required this.expiryDate,
  });
}

class ProductManager {
  final List<Product> _products = [];

  List<Product> getAllProducts() => List.unmodifiable(_products);

  void addProduct(Product product) {
    _products.add(product);
  }

  bool updateProduct(String id, {String? name, double? price, int? quantity}) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index == -1) return false;

    final old = _products[index];
    _products[index] = Product(
      id: id,
      name: name ?? old.name,
      category: old.category,
      price: price ?? old.price,
      quantity: quantity ?? old.quantity,
      expiryDate: old.expiryDate,
    );
    return true;
  }

  bool deleteProduct(String id) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index == -1) return false;
    _products.removeAt(index);
    return true;
  }

  List<Product> searchProducts(String query) {
    return _products
        .where((p) =>
    p.name.toLowerCase().contains(query.toLowerCase()) ||
        p.category.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

void main() {
  group('Pharmacist Product Management', () {
    late ProductManager manager;

    setUp(() {
      manager = ProductManager();
    });

    test('should add a new product', () {
      final product = Product(
        id: '1',
        name: 'Panadol',
        category: 'Medicines',
        price: 2.5,
        quantity: 50,
        expiryDate: '2026-01-01',
      );

      manager.addProduct(product);
      expect(manager.getAllProducts().length, 1);
      expect(manager.getAllProducts().first.name, 'Panadol');
    });

    test('should update an existing product', () {
      final product = Product(
        id: '1',
        name: 'Panadol',
        category: 'Medicines',
        price: 2.5,
        quantity: 50,
        expiryDate: '2026-01-01',
      );
      manager.addProduct(product);

      final updated = manager.updateProduct('1', name: 'Panadol Extra', price: 3.0);
      expect(updated, true);
      final updatedProduct = manager.getAllProducts().first;
      expect(updatedProduct.name, 'Panadol Extra');
      expect(updatedProduct.price, 3.0);
    });

    test('should not update non-existent product', () {
      final result = manager.updateProduct('999', name: 'Invalid');
      expect(result, false);
    });

    test('should delete a product by id', () {
      final product = Product(
        id: '1',
        name: 'Panadol',
        category: 'Medicines',
        price: 2.5,
        quantity: 50,
        expiryDate: '2026-01-01',
      );
      manager.addProduct(product);

      final deleted = manager.deleteProduct('1');
      expect(deleted, true);
      expect(manager.getAllProducts(), isEmpty);
    });

    test('should search products by name or category', () {
      manager.addProduct(Product(
        id: '1',
        name: 'Panadol',
        category: 'Medicines',
        price: 2.5,
        quantity: 50,
        expiryDate: '2026-01-01',
      ));
      manager.addProduct(Product(
        id: '2',
        name: 'Vitamin C',
        category: 'Vitamins',
        price: 1.5,
        quantity: 100,
        expiryDate: '2026-01-01',
      ));

      final result1 = manager.searchProducts('panadol');
      final result2 = manager.searchProducts('vitamins');


      expect(result1.length, 1);
      expect(result1.first.name, 'Panadol');
      expect(result2.length, 1);
      expect(result2.first.name, 'Vitamin C');
    });
  });
}
