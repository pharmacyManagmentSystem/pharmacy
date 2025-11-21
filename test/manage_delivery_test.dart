import 'package:flutter_test/flutter_test.dart';

class DeliveryPerson {
  String id;
  String name;
  String email;
  String phone;

  DeliveryPerson({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });
}

class DeliveryManager {
  final List<DeliveryPerson> _deliveries = [];

  List<DeliveryPerson> getAllDeliveryPersons() => _deliveries;

  void addDeliveryPerson(DeliveryPerson deliveryPerson) {
    _deliveries.add(deliveryPerson);
  }

  bool updateDeliveryPerson(
      String id, String newName, String newEmail, String newPhone) {
    final index = _deliveries.indexWhere((d) => d.id == id);
    if (index == -1) return false;
    _deliveries[index] = DeliveryPerson(
      id: id,
      name: newName,
      email: newEmail,
      phone: newPhone,
    );
    return true;
  }

  bool deleteDeliveryPerson(String id) {
    final index = _deliveries.indexWhere((d) => d.id == id);
    if (index == -1) return false;
    _deliveries.removeAt(index);
    return true;
  }
}

void main() {
  group('Manage Delivery Persons', () {
    late DeliveryManager manager;

    setUp(() {
      manager = DeliveryManager();
    });

    test('should add a new delivery person', () {
      final deliveryPerson = DeliveryPerson(
        id: '1',
        name: 'Alice',
        email: 'alice@example.com',
        phone: '91234567',
      );
      manager.addDeliveryPerson(deliveryPerson);
      expect(manager.getAllDeliveryPersons().length, 1);
      expect(manager.getAllDeliveryPersons().first.name, 'Alice');
    });

    test('should update delivery person details', () {
      final deliveryPerson = DeliveryPerson(
        id: '1',
        name: 'Alice',
        email: 'alice@example.com',
        phone: '91234567',
      );
      manager.addDeliveryPerson(deliveryPerson);

      final updated = manager.updateDeliveryPerson(
        '1',
        'Bob',
        'bob@example.com',
        '97765432',
      );

      expect(updated, true);
      expect(manager.getAllDeliveryPersons().first.name, 'Bob');
      expect(manager.getAllDeliveryPersons().first.email, 'bob@example.com');
    });

    test('should return false if updating non-existent delivery person', () {
      final updated = manager.updateDeliveryPerson(
        '99',
        'New Name',
        'new@example.com',
        '99999999',
      );
      expect(updated, false);
    });

    test('should delete delivery person by id', () {
      final deliveryPerson = DeliveryPerson(
        id: '1',
        name: 'Alice',
        email: 'alice@example.com',
        phone: '91234567',
      );
      manager.addDeliveryPerson(deliveryPerson);

      final deleted = manager.deleteDeliveryPerson('1');
      expect(deleted, true);
      expect(manager.getAllDeliveryPersons(), isEmpty);
    });

    test('should return empty list initially', () {
      expect(manager.getAllDeliveryPersons(), isEmpty);
    });
  });
}
