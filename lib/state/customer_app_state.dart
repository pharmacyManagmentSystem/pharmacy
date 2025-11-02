import '../services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';

/// \u202B عنوان الشحن الخاص بالعميل
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

/// \u202B تفضيلات الإشعارات
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

/// \u202B الحالة العامة للعميل
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

  /// \u202B إضافة منتج للسلة
  Future<bool> addProductToCart(Product product, {String? prescriptionUrl, String? pharmacyName, String? requestId, bool pendingApproval = false}) async {
    // \u202B إذا كان العميل يشتري من صيدلية أخرى — يمنع الخلط
    if (_currentPharmacyId != null && _currentPharmacyId != product.ownerId) {
      return false;
    }

    _currentPharmacyId ??= product.ownerId;
    _currentPharmacyName ??= pharmacyName ?? 'Unknown Pharmacy';

    final existing = _cart[product.id];
    if (existing != null) {
      existing.quantity += 1;
      existing.prescriptionUrl = prescriptionUrl ?? existing.prescriptionUrl;
      // If we now add a requested item and the existing item came from a request,
      // keep the request metadata updated.
      if (requestId != null) {
        // Note: existing.requestId is final; we only set request-pending state when creating new item.
      }
    } else {
      String? assignedRequestId = requestId;
      bool assignedPending = pendingApproval;

      // If this product requires a prescription and a prescription URL was provided,
      // create a pending_prescriptions entry and a customer_cart entry so the pharmacist
      // can review and approve/reject before checkout.
      final user = FirebaseAuth.instance.currentUser;
      if (product.requiresPrescription && (prescriptionUrl != null && prescriptionUrl.isNotEmpty) && user != null) {
        try {
          final pendingRef = DatabaseService.instance.pendingPrescriptionsRef(product.ownerId).push();
          final key = pendingRef.key;
          if (key != null) {
            assignedRequestId = key;
            assignedPending = true;

            final cartEntry = product.toCartJson(quantity: 1, prescriptionUrl: prescriptionUrl);
            cartEntry['requestId'] = key;
            cartEntry['customerId'] = user.uid;
            cartEntry['pendingApproval'] = true;
            cartEntry['createdAt'] = ServerValue.timestamp;

            // write to pending_prescriptions/<pharmacyId>/<key>
            await pendingRef.set(cartEntry);

            // also write a mirror into customer_cart/<customerId>/<key>
            await DatabaseService.instance.customerCartRef(user.uid).child(key).set(cartEntry);

            // notify the pharmacy (in-app) that a new prescription is waiting
            final notifRef = DatabaseService.instance.pharmacyNotificationsRef(product.ownerId).push();
            await notifRef.set({
              'title': 'New prescription upload',
              'body': 'A customer uploaded a prescription for "${product.name}".',
              'requestId': key,
              'createdAt': DateTime.now().toIso8601String(),
              'read': false,
            });
          }
        } catch (e) {
          // ignore DB write failures for now; local cart still contains the prescription
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

  /// Start listening to the customer's cart in Realtime Database and keep the
  /// local `_cart` in sync. Call with the Firebase user id.
  Future<void> attachCartListener(String userId) async {
    // detach previous if any
    await detachCartListener();
    try {
      _cartRef = DatabaseService.instance.customerCartRef(userId);
      // initial load + stream
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
                final product = Product.fromMap(id: productId, ownerId: ownerId, data: data);
                final quantity = data['quantity'] is num ? (data['quantity'] as num).toInt() : int.tryParse(data['quantity']?.toString() ?? '1') ?? 1;
                final prescriptionUrl = data['prescriptionUrl']?.toString();
                final requestId = data['requestId']?.toString();
                // Only consider an item pending if pendingApproval is explicitly true
                // تحقق دقيق من حالة الموافقة
                final bool isApproved = data['approved'] == true || data['status'] == 'approved';
                final pending = !isApproved && (data['pendingApproval'] == true || data['status'] == 'pending');
                final rejected = data['rejected'] == true || data['status'] == 'rejected';

                _cart[product.id] = CartItem(
                  product: product,
                  quantity: quantity,
                  prescriptionUrl: prescriptionUrl,
                  requestId: requestId,
                  pendingApproval: pending,
                  rejected: rejected,
                );
              } catch (e) {
                // ignore malformed product entries
              }
            }
          });
        }
        notifyListeners();
      });
    } catch (e) {
      print('Failed to attach cart listener: $e');
    }
  }

  /// Stop listening to remote customer cart
  Future<void> detachCartListener() async {
    try {
      await _cartSub?.cancel();
    } catch (_) {}
    _cartSub = null;
    _cartRef = null;
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

  /// التحقق من حالة الموافقة للمنتجات
  Future<bool> verifyApprovalStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    bool needsUpdate = false;
    bool allApproved = true;
    
    // تحقق من كل منتج في السلة
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
          
          // تحديث حالة المنتج إذا كانت مختلفة
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
    
    // تحديث واجهة المستخدم إذا تغيرت أي حالة
    if (needsUpdate) {
      notifyListeners();
    }
    
    return allApproved;
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

  /// Prevent submission while there are pending approvals or rejections
    final hasPending = _cart.values.any((i) => i.pendingApproval);
    if (hasPending) {
      // Double check with the database for the latest approval status
      for (final item in _cart.values.where((i) => i.pendingApproval)) {
        if (item.requestId != null) {
          final snapshot = await DatabaseService.instance
              .customerCartRef(customerId)
              .child(item.requestId!)
              .get();
          
          if (snapshot.exists && snapshot.value is Map) {
            final data = snapshot.value as Map;
            if (data['pendingApproval'] == false) {
              // Update local state if the item has been approved
              item.pendingApproval = false;
              continue;
            }
          }
        }
      }
      
      // Check again after refreshing from database
      if (_cart.values.any((i) => i.pendingApproval)) {
        throw StateError('Some items are still pending pharmacist approval');
      }
    }
    
    final hasRejected = _cart.values.any((i) => i.rejected);
    if (hasRejected) {
      throw StateError('One or more items in your cart were rejected by the pharmacist');
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


