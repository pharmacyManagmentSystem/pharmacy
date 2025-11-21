import 'package:flutter_test/flutter_test.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CustomerCartManager {
  final List<CartItem> _items = [];
  List<Product> _recommendations = [];
  String? _lastCartHash;

  List<CartItem> get items => _items;
  List<Product> get recommendations => _recommendations;

  double get total =>
      _items.fold(0, (sum, item) => sum + item.product.price * item.quantity);

  String _getCartHash() =>
      _items.isEmpty ? 'empty' : _items.map((e) => e.product.id).join(',');

  /// Add a product to cart or increase quantity if it already exists
  bool addProduct(Product product) {
    final existing = _items.where((i) => i.product.id == product.id).toList();
    if (existing.isNotEmpty) {
      final item = existing.first;
      if (item.quantity < product.stock) {
        item.quantity++;
        return true;
      }
      return false; // insufficient stock
    } else {
      if (product.stock > 0) {
        _items.add(CartItem(product: product, quantity: 1));
        return true;
      }
      return false;
    }
  }

  /// Remove a product by ID
  bool removeProduct(String id) {
    final index = _items.indexWhere((i) => i.product.id == id);
    if (index == -1) return false;
    _items.removeAt(index);
    return true;
  }

  /// Update product quantity, ensuring stock limits
  bool updateQuantity(String id, int newQty) {
    final index = _items.indexWhere((i) => i.product.id == id);
    if (index == -1) return false;
    final item = _items[index];
    if (newQty <= 0) {
      _items.removeAt(index);
      return true;
    }
    if (newQty > item.product.stock) return false;
    item.quantity = newQty;
    return true;
  }

  /// Generate product recommendations (excluding items in cart and out of stock)
  Future<void> loadRecommendations(List<Product> allProducts) async {
    final currentHash = _getCartHash();
    if (_lastCartHash == currentHash && _recommendations.isNotEmpty) return;

    _lastCartHash = currentHash;
    final cartIds = _items.map((i) => i.product.id).toSet();

    _recommendations = allProducts
        .where((p) => !cartIds.contains(p.id) && p.stock > 0)
        .take(3)
        .toList();
  }
}

void main() {
  group('CustomerCartManager', () {
    late CustomerCartManager cart;
    late Product p1;
    late Product p2;
    late Product p3;
    late Product p4;

    setUp(() {
      cart = CustomerCartManager();
      p1 = Product(id: '1', name: 'Panadol', price: 2.5, stock: 10);
      p2 = Product(id: '2', name: 'Aspirin', price: 1.5, stock: 5);
      p3 = Product(id: '3', name: 'Vitamin C', price: 3.0, stock: 2);
      p4 = Product(id: '4', name: 'Expired Drug', price: 4.0, stock: 0);
    });

    test('should add new product to cart', () {
      final added = cart.addProduct(p1);
      expect(added, true);
      expect(cart.items.length, 1);
      expect(cart.items.first.product.name, 'Panadol');
    });

    test('should increase quantity if same product added again', () {
      cart.addProduct(p1);
      final added = cart.addProduct(p1);
      expect(added, true);
      expect(cart.items.first.quantity, 2);
    });

    test('should not exceed stock limit when adding', () {
      final lowStock = Product(id: '5', name: 'Item', price: 1.0, stock: 1);
      cart.addProduct(lowStock);
      final addedAgain = cart.addProduct(lowStock);
      expect(addedAgain, false);
      expect(cart.items.first.quantity, 1);
    });

    test('should remove a product by id', () {
      cart.addProduct(p1);
      final removed = cart.removeProduct('1');
      expect(removed, true);
      expect(cart.items.isEmpty, true);
    });

    test('should update product quantity within stock', () {
      cart.addProduct(p2);
      final updated = cart.updateQuantity('2', 3);
      expect(updated, true);
      expect(cart.items.first.quantity, 3);
    });

    test('should fail to update quantity beyond stock', () {
      cart.addProduct(p3);
      final updated = cart.updateQuantity('3', 10);
      expect(updated, false);
    });

    test('should calculate total price correctly', () {
      cart.addProduct(p1);
      cart.addProduct(p2);
      cart.updateQuantity('1', 2); // 2 * 2.5 = 5.0
      // total = 5.0 + 1.5 = 6.5
      expect(cart.total, 6.5);
    });

    test('should generate product recommendations excluding items in cart',
            () async {
          cart.addProduct(p1);
          final all = [p1, p2, p3, p4];
          await cart.loadRecommendations(all);

          // Should exclude p1 (in cart) and p4 (stock = 0)
          expect(cart.recommendations.any((r) => r.id == '1'), false);
          expect(cart.recommendations.any((r) => r.id == '4'), false);
          expect(cart.recommendations.length, 2); // Only p2 and p3 remain
        });

    test('should not reload recommendations if cart unchanged', () async {
      cart.addProduct(p1);
      final all = [p1, p2, p3];
      await cart.loadRecommendations(all);
      final initial = List<Product>.from(cart.recommendations);
      await cart.loadRecommendations(all); // same cart, should skip
      expect(cart.recommendations, initial);
    });
  });
}
