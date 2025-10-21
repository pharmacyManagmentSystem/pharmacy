import 'package:firebase_database/firebase_database.dart';

/// Central access point for all Firebase Realtime Database interactions.
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  FirebaseDatabase get database => _database;

  DatabaseReference root() => _database.ref();

  DatabaseReference ref(String path) => _database.ref(path);

  DatabaseReference pharmacyCollection(String segment) =>
      _database.ref('pharmacy/$segment');

  DatabaseReference customersRef() => pharmacyCollection('customers');

  DatabaseReference customerRef(String userId) => customersRef().child(userId);

  DatabaseReference pharmacistsRef() => pharmacyCollection('pharmacists');

  DatabaseReference pharmacistRef(String userId) =>
      pharmacistsRef().child(userId);

  DatabaseReference deliveryPersonsRef() =>
      pharmacyCollection('delivery_persons');

  DatabaseReference adminsRef() => pharmacyCollection('admins');

  DatabaseReference ordersRef() => _database.ref('orders');

  DatabaseReference orderRef(String orderId) => ordersRef().child(orderId);

  DatabaseReference customerOrdersRef(String customerId) =>
      _database.ref('customer_orders/$customerId');

  DatabaseReference pharmacyOrdersRef(String pharmacyId) =>
      _database.ref('pharmacy_orders/$pharmacyId');

  DatabaseReference customerCartRef(String customerId) =>
      _database.ref('customer_cart/$customerId');

  DatabaseReference pharmacistProductsRef(String ownerId) =>
      _database.ref('products/$ownerId');

  DatabaseReference productRequestsRef(String pharmacyId) =>
      _database.ref('product_requests/$pharmacyId');

  DatabaseReference notificationSettingsRef(String userId) =>
      _database.ref('notification_settings/$userId');

  DatabaseReference expiryTrackerRef(String pharmacistId) =>
      _database.ref('products/$pharmacistId');

  Future<DataSnapshot> fetchOnce(DatabaseReference reference) =>
      reference.get();

  Stream<DatabaseEvent> watch(DatabaseReference reference) =>
      reference.onValue;

  String generatePushKey(DatabaseReference reference) {
    final key = reference.push().key;
    if (key == null) {
      throw StateError('Unable to generate key for ${reference.path}');
    }
    return key;
  }

  String generateOrderId() => generatePushKey(ordersRef());

  Future<void> set(DatabaseReference reference, Object? value) =>
      reference.set(value);

  Future<void> update(DatabaseReference reference, Map<String, Object?> data) =>
      reference.update(data);

  Future<void> fanOut(Map<String, Object?> updates) => root().update(updates);

  Future<void> clearCustomerCart(String customerId) =>
      customerCartRef(customerId).remove();
}
