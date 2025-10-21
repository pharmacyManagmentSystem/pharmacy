import '../services/database_service.dart';
import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';

/// عنوان الشحن الخاص بالعميل
class CustomerShippingAddress {
  const CustomerShippingAddress({
    required this.houseNumber,
    required this.roadNumber,
    required this.additionalDirections,
    this.latitude,
    this.longitude,
  });

  final String houseNumber;
  final String roadNumber;
  final String additionalDirections;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toMap() {
    return {
      'houseNumber': houseNumber,
      'roadNumber': roadNumber,
      'additionalDirections': additionalDirections,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// تفضيلات الإشعارات
class NotificationPreferences {
  NotificationPreferences({
    this.newProductRequest = true,
    this.productExpiry = true,
    this.prescriptionUploaded = true,
    this.email = true,
    this.inApp = true,
  });

  bool newProductRequest;
  bool productExpiry;
  bool prescriptionUploaded;
  bool email;
  bool inApp;

  Map<String, dynamic> toMap() {
    return {
      'newProductRequest': newProductRequest,
      'productExpirySoon': productExpiry,
      'newPrescriptionUploaded': prescriptionUploaded,
      'byEmail': email,
      'inApp': inApp,
    };
  }
}

/// الحالة العامة للعميل
class CustomerAppState extends ChangeNotifier {
  final Map<String, CartItem> _cart = {};
  String? _currentPharmacyId;
  String? _currentPharmacyName;
  CustomerShippingAddress? _shippingAddress;
  NotificationPreferences notificationPreferences = NotificationPreferences();

  List<CartItem> get cartItems => _cart.values.toList();
  bool get hasCartItems => _cart.isNotEmpty;
  double get cartTotal => _cart.values.fold(0, (sum, item) => sum + item.total);
  String? get currentPharmacyId => _currentPharmacyId;
  String? get currentPharmacyName => _currentPharmacyName;
  CustomerShippingAddress? get shippingAddress => _shippingAddress;

  /// إضافة منتج للسلة
  bool addProductToCart(Product product, {String? prescriptionUrl, String? pharmacyName}) {
    // 🔹إذا كان العميل يشتري من صيدلية أخرى — يمنع الخلط
    if (_currentPharmacyId != null && _currentPharmacyId != product.ownerId) {
      return false;
    }

    _currentPharmacyId ??= product.ownerId;
    _currentPharmacyName ??= pharmacyName ?? 'Unknown Pharmacy';

    final existing = _cart[product.id];
    if (existing != null) {
      existing.quantity += 1;
      existing.prescriptionUrl = prescriptionUrl ?? existing.prescriptionUrl;
    } else {
      _cart[product.id] = CartItem(
        product: product,
        quantity: 1,
        prescriptionUrl: prescriptionUrl,
      );
    }

    notifyListeners();
    return true;
  }

  /// تحديث الكمية
  void updateQuantity(String productId, int quantity) {
    final item = _cart[productId];
    if (item == null) return;
    if (quantity <= 0) {
      _cart.remove(productId);
    } else {
      item.quantity = quantity;
    }

    if (_cart.isEmpty) {
      _currentPharmacyId = null;
      _currentPharmacyName = null;
    }

    notifyListeners();
  }

  /// إزالة منتج
  void removeItem(String productId) {
    _cart.remove(productId);
    if (_cart.isEmpty) {
      _currentPharmacyId = null;
      _currentPharmacyName = null;
    }
    notifyListeners();
  }

  /// تفريغ السلة
  void clearCart() {
    _cart.clear();
    _currentPharmacyId = null;
    _currentPharmacyName = null;
    notifyListeners();
  }

  /// تعيين الصيدلية الحالية
  void setCurrentPharmacy(String pharmacyId, String pharmacyName) {
    _currentPharmacyId = pharmacyId;
    _currentPharmacyName = pharmacyName;
    notifyListeners();
  }

  /// تعيين عنوان الشحن
  void setShippingAddress(CustomerShippingAddress address) {
    _shippingAddress = address;
    notifyListeners();
  }

  /// تحديث إعدادات الإشعارات
  void updateNotificationPreferences(NotificationPreferences prefs) {
    notificationPreferences = prefs;
    notifyListeners();
  }

  /// إرسال الطلب إلى قاعدة البيانات
  Future<String> submitOrder({
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String pharmacyId,
    required String pharmacyName,
    required String paymentMethod,
    String? notes,
  }) async {
    if (_cart.isEmpty) {
      throw StateError('Cart is empty');
    }

    final address = _shippingAddress;
    if (address == null) {
      throw StateError('Shipping address is missing');
    }

    final orderId = DatabaseService.instance.root().child('orders').push().key;
    if (orderId == null) {
      throw StateError('Unable to generate order ID');
    }

    final items = <String, dynamic>{};
    for (final entry in _cart.entries) {
      items[entry.key] = entry.value.product.toCartJson(
        quantity: entry.value.quantity,
        prescriptionUrl: entry.value.prescriptionUrl,
      );
    }

    final orderMap = {
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'total': cartTotal,
      'status': orderStatusToString(OrderStatus.awaitingConfirmation),
      'createdAt': DateTime.now().toIso8601String(),
      'address': address.toMap(),
      'items': items,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };

    final rootRef = DatabaseService.instance.root();
    await rootRef.update({
      'orders/$orderId': orderMap,
      'customer_orders/$customerId/$orderId': orderMap,
      'pharmacy_orders/$pharmacyId/$orderId': orderMap,
    });

    // مسح السلة بعد الإرسال
    await DatabaseService.instance.ref('customer_cart/$customerId').remove();

    clearCart();
    _shippingAddress = null;

    return orderId;
  }
}


