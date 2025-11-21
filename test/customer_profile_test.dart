import 'package:flutter_test/flutter_test.dart';

class CustomerProfile {
  String id;
  String name;
  String email;
  String phone;
  String address;
  bool darkMode;

  CustomerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.darkMode = false,
  });
}

class CustomerProfileManager {
  final List<CustomerProfile> _profiles = [];

  List<CustomerProfile> getAllProfiles() => _profiles;

  void addProfile(CustomerProfile profile) {
    _profiles.add(profile);
  }

  bool updateProfile(
      String id, {
        String? newName,
        String? newPhone,
        String? newAddress,
        bool? newDarkMode,
      }) {
    final index = _profiles.indexWhere((p) => p.id == id);
    if (index == -1) return false;

    final old = _profiles[index];
    _profiles[index] = CustomerProfile(
      id: old.id,
      name: newName ?? old.name,
      email: old.email,
      phone: newPhone ?? old.phone,
      address: newAddress ?? old.address,
      darkMode: newDarkMode ?? old.darkMode,
    );
    return true;
  }

  bool deleteProfile(String id) {
    final index = _profiles.indexWhere((p) => p.id == id);
    if (index == -1) return false;
    _profiles.removeAt(index);
    return true;
  }

  bool validatePasswordStrength(String password) {
    final regex =
    RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{6,}$');
    return regex.hasMatch(password);
  }
}

void main() {
  group('CustomerProfileManager', () {
    late CustomerProfileManager manager;

    setUp(() {
      manager = CustomerProfileManager();
    });

    test('should add a new profile', () {
      final profile = CustomerProfile(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '91234567',
        address: '123 Main St',
      );
      manager.addProfile(profile);
      expect(manager.getAllProfiles().length, 1);
      expect(manager.getAllProfiles().first.name, 'John Doe');
    });

    test('should update profile details', () {
      final profile = CustomerProfile(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '91234567',
        address: '123 Main St',
      );
      manager.addProfile(profile);

      final updated = manager.updateProfile(
        '1',
        newName: 'Jane Doe',
        newPhone: '97765432',
        newAddress: '456 New Ave',
        newDarkMode: true,
      );

      expect(updated, true);
      final updatedProfile = manager.getAllProfiles().first;
      expect(updatedProfile.name, 'Jane Doe');
      expect(updatedProfile.phone, '97765432');
      expect(updatedProfile.darkMode, true);
    });

    test('should return false if updating non-existent profile', () {
      final updated = manager.updateProfile('99', newName: 'Someone Else');
      expect(updated, false);
    });

    test('should delete profile by id', () {
      final profile = CustomerProfile(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '91234567',
        address: '123 Main St',
      );
      manager.addProfile(profile);

      final deleted = manager.deleteProfile('1');
      expect(deleted, true);
      expect(manager.getAllProfiles(), isEmpty);
    });

    test('should return empty list initially', () {
      expect(manager.getAllProfiles(), isEmpty);
    });

    test('should validate strong passwords correctly', () {
      // Valid examples
      expect(manager.validatePasswordStrength('Abc123!'), true);
      expect(manager.validatePasswordStrength('GoodPass1@'), true);

      // Invalid examples
      expect(manager.validatePasswordStrength('abc123'), false); // no uppercase/special
      expect(manager.validatePasswordStrength('ABC123!'), false); // no lowercase
      expect(manager.validatePasswordStrength('Ab1'), false); // too short
    });
  });
}
