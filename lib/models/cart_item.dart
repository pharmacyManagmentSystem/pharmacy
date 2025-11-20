import 'product.dart';

class CartItem {
  CartItem({
    required this.product,
    required this.quantity,
    this.prescriptionUrl,
    this.requestId,
    this.pendingApproval = false,
    this.rejected = false,
  });

  final Product product;
  int quantity;
  String? prescriptionUrl;
  final String? requestId;
  bool pendingApproval;
  bool rejected;

  double get total => product.price * quantity;

  void updateFromDatabase(Map<dynamic, dynamic> data) {
    final bool isApproved = data['approved'] == true ||
        data['status'] == 'approved' ||
        data['pendingApproval'] == false;

    if (isApproved) {
      pendingApproval = false;
      rejected = false;
    } else if (data['rejected'] == true || data['status'] == 'rejected') {
      rejected = true;
      pendingApproval = false;
    }
  }
}
