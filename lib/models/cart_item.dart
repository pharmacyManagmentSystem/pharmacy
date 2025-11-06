import 'product.dart';

class CartItem {
  CartItem({
    required this.product,
    required this.quantity,
    this.prescriptionUrl,
  });

  final Product product;
  int quantity;
  String? prescriptionUrl;

  double get total => product.price * quantity;
}
