import 'package:flutter_test/flutter_test.dart';
// Imports the Flutter testing framework to enable writing unit tests.

class Product {
  // Defines a model class to represent a product in inventory.
  String id;          // Unique identifier for the product.
  String name;        // Name of the product.
  String category;    // Category of the product (e.g., Medicines, Vitamins).
  double price;       // Price of the product.
  int quantity;       // Quantity available in stock.
  String expiryDate;  // Expiry date of the product as a string.

  Product({
    required this.id,          // Requires a unique ID when creating a product.
    required this.name,        // Requires a name when creating a product.
    required this.category,    // Requires a category.
    required this.price,       // Requires a price.
    required this.quantity,    // Requires a quantity.
    required this.expiryDate,  // Requires an expiry date.
  });
}

class ProductManager {
  // Manages a collection of products and provides CRUD operations.
  final List<Product> _products = [];
  // Internal private list to store products.

  List<Product> getAllProducts() => List.unmodifiable(_products);
  // Returns all products as a read-only list to prevent external modification.

  void addProduct(Product product) {
    _products.add(product);
    // Adds a new product to the internal list.
  }

  bool updateProduct(String id, {String? name, double? price, int? quantity}) {
    // Updates an existing product by ID; optional parameters allow partial updates.
    final index = _products.indexWhere((p) => p.id == id);
    // Finds the index of the product with the given ID.
    if (index == -1) return false;
    // Returns false if no product is found with the given ID.

    final old = _products[index];
    // Stores the existing product at that index.
    _products[index] = Product(
      id: id,
      name: name ?? old.name,
      // Updates the name if provided; otherwise keeps the old name.
      category: old.category,
      // Keeps the original category unchanged.
      price: price ?? old.price,
      // Updates price if provided; otherwise keeps the old price.
      quantity: quantity ?? old.quantity,
      // Updates quantity if provided; otherwise keeps the old quantity.
      expiryDate: old.expiryDate,
      // Keeps expiry date unchanged.
    );
    return true;
    // Returns true to indicate successful update.
  }

  bool deleteProduct(String id) {
    // Deletes a product by its ID.
    final index = _products.indexWhere((p) => p.id == id);
    // Finds the index of the product to delete.
    if (index == -1) return false;
    // Returns false if product not found.
    _products.removeAt(index);
    // Removes the product from the list.
    return true;
    // Returns true to indicate successful deletion.
  }

  List<Product> searchProducts(String query) {
    // Searches for products by name or category.
    return _products
        .where((p) =>
    p.name.toLowerCase().contains(query.toLowerCase()) ||
        p.category.toLowerCase().contains(query.toLowerCase()))
        .toList();
    // Returns a list of products where the name or category matches the query, ignoring case.
  }
}

void main() {
  // Entry point for the test suite.
  group('Pharmacist Product Management', () {
    // Groups related tests together under a descriptive name.
    late ProductManager manager;
    // Declares a variable for ProductManager; 'late' allows initialization in setUp.

    setUp(() {
      manager = ProductManager();
      // Runs before each test; initializes a fresh ProductManager instance.
    });

    test('should add a new product', () {
      // Test to verify adding a product works.
      final product = Product(
        id: '1',
        name: 'Panadol',
        category: 'Medicines',
        price: 2.5,
        quantity: 50,
        expiryDate: '2026-01-01',
      );

      manager.addProduct(product);
      // Adds product to the manager.
      expect(manager.getAllProducts().length, 1);
      // Checks that exactly one product exists.
      expect(manager.getAllProducts().first.name, 'Panadol');
      // Checks that the first product's name is correct.
    });

    test('should update an existing product', () {
      // Test to verify updating a product works.
      final product = Product(
        id: '1',
        name: 'Panadol',
        category: 'Medicines',
        price: 2.5,
        quantity: 50,
        expiryDate: '2026-01-01',
      );
      manager.addProduct(product);
      // Adds initial product.

      final updated = manager.updateProduct('1', name: 'Panadol Extra', price: 3.0);
      // Updates the product name and price.
      expect(updated, true);
      // Expects update to succeed.
      final updatedProduct = manager.getAllProducts().first;
      // Retrieves the updated product.
      expect(updatedProduct.name, 'Panadol Extra');
      // Checks updated name.
      expect(updatedProduct.price, 3.0);
      // Checks updated price.
    });

    test('should not update non-existent product', () {
      // Test updating a product that does not exist.
      final result = manager.updateProduct('999', name: 'Invalid');
      // Attempts update.
      expect(result, false);
      // Expects failure (false).
    });

    test('should delete a product by id', () {
      // Test deleting a product.
      final product = Product(
        id: '1',
        name: 'Panadol',
        category: 'Medicines',
        price: 2.5,
        quantity: 50,
        expiryDate: '2026-01-01',
      );
      manager.addProduct(product);
      // Adds product.

      final deleted = manager.deleteProduct('1');
      // Deletes product by ID.
      expect(deleted, true);
      // Expects deletion to succeed.
      expect(manager.getAllProducts(), isEmpty);
      // Expects product list to be empty.
    });

    test('should search products by name or category', () {
      // Test search functionality.
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
      // Search by name.
      final result2 = manager.searchProducts('vitamins');
      // Search by category.

      expect(result1.length, 1);
      // Expects one match.
      expect(result1.first.name, 'Panadol');
      // Checks product name.
      expect(result2.length, 1);
      // Expects one match.
      expect(result2.first.name, 'Vitamin C');
      // Checks product name.
    });
  });
}
