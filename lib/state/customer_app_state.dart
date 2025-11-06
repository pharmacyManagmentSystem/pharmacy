import '../services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';

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

class CustomerAppState extends ChangeNotifier {
  final Map<String, CartItem> _cart = {};
  StreamSubscription<DatabaseEvent>? _cartSub;
  DatabaseReference? _cartRef;
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

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<bool> addProductToCart(Product product,
      {String? prescriptionUrl,
      String? pharmacyName,
      String? requestId,
      bool pendingApproval = false}) async {
    if (_currentPharmacyId != null && _currentPharmacyId != product.ownerId) {
      return false;
    }

    _currentPharmacyId ??= product.ownerId;
    _currentPharmacyName ??= pharmacyName ?? 'Unknown Pharmacy';

    try {
      final productsRef =
          DatabaseService.instance.ref('products/${product.ownerId}');
      final productSnapshot = await productsRef.child(product.id).get();

      if (productSnapshot.exists && productSnapshot.value is Map) {
        final productData = productSnapshot.value as Map;
        final availableQuantity = productData['quantity'] is num
            ? (productData['quantity'] as num).toInt()
            : int.tryParse(productData['quantity']?.toString() ?? '0') ?? 0;

        if (availableQuantity <= 0) {
          return false;
        }
      }
    } catch (e) {
      print('Error checking stock when adding to cart: $e');
    }

    final existing = _cart[product.id];
    if (existing != null) {
      try {
        final productsRef =
            DatabaseService.instance.ref('products/${product.ownerId}');
        final productSnapshot = await productsRef.child(product.id).get();

        if (productSnapshot.exists && productSnapshot.value is Map) {
          final productData = productSnapshot.value as Map;
          final availableQuantity = productData['quantity'] is num
              ? (productData['quantity'] as num).toInt()
              : int.tryParse(productData['quantity']?.toString() ?? '0') ?? 0;

          if (existing.quantity + 1 > availableQuantity) {
            return false;
          }
        }
      } catch (e) {
        print('Error checking stock when incrementing quantity: $e');
      }

      existing.quantity += 1;
      existing.prescriptionUrl = prescriptionUrl ?? existing.prescriptionUrl;
    } else {
      String? assignedRequestId = requestId;
      bool assignedPending = pendingApproval;

      final user = FirebaseAuth.instance.currentUser;
      if (product.requiresPrescription &&
          (prescriptionUrl != null && prescriptionUrl.isNotEmpty) &&
          user != null) {
        try {
          final pendingRef = DatabaseService.instance
              .pendingPrescriptionsRef(product.ownerId)
              .push();
          final key = pendingRef.key;
          if (key != null) {
            assignedRequestId = key;
            assignedPending = true;

            final cartEntry = product.toCartJson(
                quantity: 1, prescriptionUrl: prescriptionUrl);
            cartEntry['requestId'] = key;
            cartEntry['customerId'] = user.uid;
            cartEntry['pendingApproval'] = true;
            cartEntry['createdAt'] = ServerValue.timestamp;

            await pendingRef.set(cartEntry);

            await DatabaseService.instance
                .customerCartRef(user.uid)
                .child(key)
                .set(cartEntry);

            final notifRef = DatabaseService.instance
                .pharmacyNotificationsRef(product.ownerId)
                .push();
            await notifRef.set({
              'title': 'New prescription upload',
              'body':
                  'A customer uploaded a prescription for "${product.name}".',
              'requestId': key,
              'createdAt': DateTime.now().toIso8601String(),
              'read': false,
            });
          }
        } catch (e) {
          print('Failed to create pending prescription entry: $e');
        }
      }

      _cart[product.id] = CartItem(
        product: product,
        quantity: 1,
        prescriptionUrl: prescriptionUrl,
        requestId: assignedRequestId,
        pendingApproval: assignedPending,
      );
    }

    notifyListeners();
    return true;
  }

  Future<void> attachCartListener(String userId) async {
    await detachCartListener();
    try {
      _cartRef = DatabaseService.instance.customerCartRef(userId);
      _cartSub = _cartRef!.onValue.listen((event) {
        final raw = event.snapshot.value;
        _cart.clear();
        if (raw is Map) {
          raw.forEach((key, value) {
            if (value is Map) {
              final data = Map<dynamic, dynamic>.from(value);
              final productId = data['productId']?.toString() ?? key.toString();
              final ownerId = data['ownerId']?.toString() ?? '';
              try {
                final product = Product.fromMap(
                    id: productId, ownerId: ownerId, data: data);
                final quantity = data['quantity'] is num
                    ? (data['quantity'] as num).toInt()
                    : int.tryParse(data['quantity']?.toString() ?? '1') ?? 1;
                final prescriptionUrl = data['prescriptionUrl']?.toString();
                final requestId = data['requestId']?.toString();
                final bool isApproved =
                    data['approved'] == true || data['status'] == 'approved';
                final pending = !isApproved &&
                    (data['pendingApproval'] == true ||
                        data['status'] == 'pending');
                final rejected =
                    data['rejected'] == true || data['status'] == 'rejected';

                _cart[product.id] = CartItem(
                  product: product,
                  quantity: quantity,
                  prescriptionUrl: prescriptionUrl,
                  requestId: requestId,
                  pendingApproval: pending,
                  rejected: rejected,
                );
              } catch (e) {}
            }
          });
        }
        notifyListeners();
      });
    } catch (e) {
      print('Failed to attach cart listener: $e');
    }
  }

  Future<void> detachCartListener() async {
    try {
      await _cartSub?.cancel();
    } catch (_) {}
    _cartSub = null;
    _cartRef = null;
  }

  Future<bool> updateQuantity(String productId, int quantity) async {
    final item = _cart[productId];
    if (item == null) return false;

    if (quantity <= 0) {
      _cart.remove(productId);
      if (_cart.isEmpty) {
        _currentPharmacyId = null;
        _currentPharmacyName = null;
      }
      notifyListeners();
      return true;
    }

    if (quantity > item.quantity && _currentPharmacyId != null) {
      try {
        final productsRef =
            DatabaseService.instance.ref('products/$_currentPharmacyId');
        final productSnapshot = await productsRef.child(productId).get();

        if (productSnapshot.exists && productSnapshot.value is Map) {
          final productData = productSnapshot.value as Map;
          final availableQuantity = productData['quantity'] is num
              ? (productData['quantity'] as num).toInt()
              : int.tryParse(productData['quantity']?.toString() ?? '0') ?? 0;

          if (quantity > availableQuantity) {
            return false;
          }
        }
      } catch (e) {
        print('Error checking stock: $e');
      }
    }

    item.quantity = quantity;

    if (_cart.isEmpty) {
      _currentPharmacyId = null;
      _currentPharmacyName = null;
    }

    notifyListeners();
    return true;
  }

  void removeItem(String productId) {
    _cart.remove(productId);
    if (_cart.isEmpty) {
      _currentPharmacyId = null;
      _currentPharmacyName = null;
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _currentPharmacyId = null;
    _currentPharmacyName = null;
    notifyListeners();
  }

  void setCurrentPharmacy(String pharmacyId, String pharmacyName) {
    _currentPharmacyId = pharmacyId;
    _currentPharmacyName = pharmacyName;
    notifyListeners();
  }

  void setShippingAddress(CustomerShippingAddress address) {
    _shippingAddress = address;
    notifyListeners();
  }

  void updateNotificationPreferences(NotificationPreferences prefs) {
    notificationPreferences = prefs;
    notifyListeners();
  }

  Future<bool> verifyApprovalStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    bool needsUpdate = false;
    bool allApproved = true;

    for (var item in _cart.values) {
      if (item.requestId != null) {
        final snapshot = await DatabaseService.instance
            .customerCartRef(user.uid)
            .child(item.requestId!)
            .get();

        if (snapshot.exists && snapshot.value is Map) {
          final data = snapshot.value as Map;
          bool isApproved = data['approved'] == true ||
              data['status'] == 'approved' ||
              data['pendingApproval'] == false;

          if (item.pendingApproval == isApproved) {
            item.pendingApproval = !isApproved;
            needsUpdate = true;
          }

          if (!isApproved) {
            allApproved = false;
          }
        }
      }
    }

    if (needsUpdate) {
      notifyListeners();
    }

    return allApproved;
  }

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

    final hasPending = _cart.values.any((i) => i.pendingApproval);
    if (hasPending) {
      for (final item in _cart.values.where((i) => i.pendingApproval)) {
        if (item.requestId != null) {
          final snapshot = await DatabaseService.instance
              .customerCartRef(customerId)
              .child(item.requestId!)
              .get();

          if (snapshot.exists && snapshot.value is Map) {
            final data = snapshot.value as Map;
            if (data['pendingApproval'] == false) {
              item.pendingApproval = false;
              continue;
            }
          }
        }
      }

      if (_cart.values.any((i) => i.pendingApproval)) {
        throw StateError('Some items are still pending pharmacist approval');
      }
    }

    final hasRejected = _cart.values.any((i) => i.rejected);
    if (hasRejected) {
      throw StateError(
          'One or more items in your cart were rejected by the pharmacist');
    }

    final productsRef = DatabaseService.instance.ref('products/$pharmacyId');
    final updates = <String, dynamic>{};

    for (final entry in _cart.entries) {
      final cartItem = entry.value;
      final productSnapshot =
          await productsRef.child(cartItem.product.id).get();

      if (!productSnapshot.exists) {
        throw StateError(
            'Product "${cartItem.product.name}" is no longer available');
      }

      final productData = productSnapshot.value as Map;
      final availableQuantity = productData['quantity'] is num
          ? (productData['quantity'] as num).toInt()
          : int.tryParse(productData['quantity']?.toString() ?? '0') ?? 0;

      if (cartItem.quantity > availableQuantity) {
        throw StateError(
            'Insufficient stock for "${cartItem.product.name}". Available: $availableQuantity, Requested: ${cartItem.quantity}');
      }

      final newQuantity = availableQuantity - cartItem.quantity;
      updates['products/$pharmacyId/${cartItem.product.id}/quantity'] =
          newQuantity;
      updates['products/$pharmacyId/${cartItem.product.id}/status'] =
          newQuantity > 0 ? 'in_stock' : 'out_of_stock';
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

    updates['orders/$orderId'] = orderMap;
    updates['customer_orders/$customerId/$orderId'] = orderMap;
    updates['pharmacy_orders/$pharmacyId/$orderId'] = orderMap;

    final rootRef = DatabaseService.instance.root();
    await rootRef.update(updates);

    await DatabaseService.instance.ref('customer_cart/$customerId').remove();

    clearCart();
    _shippingAddress = null;

    return orderId;
  }
}
