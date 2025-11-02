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

  /// If this cart item was created from a customer product request, store the
  /// originating request id here so we can track approval.
  final String? requestId;

  /// True when the item requires pharmacist approval before checkout.
  bool pendingApproval;

  /// True when the pharmacist rejected the uploaded prescription/request.
  bool rejected;

  double get total => product.price * quantity;

  /// Update approval status from database data
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
