import 'package:flutter_test/flutter_test.dart';

class Pharmacist {
  String id;
  String name;
  String email;
  String phone;
  String address;

  Pharmacist({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
  });
}

class PharmacistManager {
  final List<Pharmacist> _pharmacists = [];

  List<Pharmacist> getAllPharmacists() => _pharmacists;

  void addPharmacist(Pharmacist pharmacist) {
    _pharmacists.add(pharmacist);
  }

  bool updatePharmacist(String id, String newName, String newEmail,
      String newPhone, String newAddress) {
    final index = _pharmacists.indexWhere((p) => p.id == id);
    if (index == -1) return false;
    _pharmacists[index] = Pharmacist(
      id: id,
      name: newName,
      email: newEmail,
      phone: newPhone,
      address: newAddress,
    );
    return true;
  }

  bool deletePharmacist(String id) {
    final index = _pharmacists.indexWhere((p) => p.id == id);
    if (index == -1) return false;
    _pharmacists.removeAt(index);
    return true;
  }
}

void main() {
  group('Manage Pharmacists', () {
    late PharmacistManager manager;

    setUp(() {
      manager = PharmacistManager();
    });

    test('should add a new pharmacist', () {
      final pharmacist = Pharmacist(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '91234567',
        address: '123 Main St',
      );
      manager.addPharmacist(pharmacist);
      expect(manager.getAllPharmacists().length, 1);
      expect(manager.getAllPharmacists().first.name, 'John Doe');
    });

    test('should update pharmacist details', () {
      final pharmacist = Pharmacist(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '91234567',
        address: '123 Main St',
      );
      manager.addPharmacist(pharmacist);

      final updated = manager.updatePharmacist(
        '1',
        'Jane Doe',
        'jane@example.com',
        '97765432',
        '456 New Ave',
      );

      expect(updated, true);
      expect(manager.getAllPharmacists().first.name, 'Jane Doe');
      expect(manager.getAllPharmacists().first.address, '456 New Ave');
    });

    test('should return false if updating non-existent pharmacist', () {
      final updated = manager.updatePharmacist(
        '99',
        'New Name',
        'new@example.com',
        '99999999',
        'No Address',
      );
      expect(updated, false);
    });

    test('should delete pharmacist by id', () {
      final pharmacist = Pharmacist(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '91234567',
        address: '123 Main St',
      );
      manager.addPharmacist(pharmacist);

      final deleted = manager.deletePharmacist('1');
      expect(deleted, true);
      expect(manager.getAllPharmacists(), isEmpty);
    });

    test('should return empty list initially', () {
      expect(manager.getAllPharmacists(), isEmpty);
    });
  });
}
