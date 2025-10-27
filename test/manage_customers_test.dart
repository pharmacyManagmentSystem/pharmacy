import 'package:flutter_test/flutter_test.dart';

class Customer {
  String id;
  String name;
  String email;
  String phone;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });
}

class CustomerManager {
  final List<Customer> _customers = [];

  List<Customer> getAllCustomers() => _customers;

  void addCustomer(Customer customer) {
    _customers.add(customer);
  }

  bool updateCustomer(String id, String newName, String newEmail, String newPhone) {
    final index = _customers.indexWhere((c) => c.id == id);
    if (index == -1) return false;
    _customers[index] = Customer(id: id, name: newName, email: newEmail, phone: newPhone);
    return true;
  }

  // Corrected delete implementation
  bool deleteCustomer(String id) {
    final index = _customers.indexWhere((c) => c.id == id);
    if (index == -1) return false;
    _customers.removeAt(index);
    return true;
  }
}

void main() {
  group('Manage Customers', () {
    late CustomerManager manager;

    setUp(() {
      manager = CustomerManager();
    });

    test('should add a new customer', () {
      final customer = Customer(id: '1', name: 'John Doe', email: 'john@example.com', phone: '91234567');
      manager.addCustomer(customer);
      expect(manager.getAllCustomers().length, 1);
      expect(manager.getAllCustomers().first.name, 'John Doe');
    });

    test('should update customer details', () {
      final customer = Customer(id: '1', name: 'John Doe', email: 'john@example.com', phone: '91234567');
      manager.addCustomer(customer);

      final updated = manager.updateCustomer('1', 'Jane Doe', 'jane@example.com', '97765432');
      expect(updated, true);
      expect(manager.getAllCustomers().first.name, 'Jane Doe');
    });

    test('should return false if updating non-existent customer', () {
      final updated = manager.updateCustomer('99', 'New Name', 'new@example.com', '99999999');
      expect(updated, false);
    });

    test('should delete customer by id', () {
      final customer = Customer(id: '1', name: 'John Doe', email: 'john@example.com', phone: '91234567');
      manager.addCustomer(customer);

      final deleted = manager.deleteCustomer('1');
      expect(deleted, true);
      expect(manager.getAllCustomers(), isEmpty);
    });

    test('should return empty list initially', () {
      expect(manager.getAllCustomers(), isEmpty);
    });
  });
}
