import 'package:flutter_test/flutter_test.dart';

class PaymentInfo {
  final String name;
  final String cardNumber;
  final String cvv;

  PaymentInfo({
    required this.name,
    required this.cardNumber,
    required this.cvv,
  });
}

class PaymentManager {
  bool validateName(String name) {
    final nameReg = RegExp(r'^[A-Za-z ]+$');
    if (name.trim().isEmpty) return false;
    return nameReg.hasMatch(name.trim());
  }

  bool validateCardNumber(String card) {
    final cardReg = RegExp(r'^\d{16}$');
    return cardReg.hasMatch(card);
  }

  bool validateCvv(String cvv) {
    final cvvReg = RegExp(r'^\d{3}$');
    return cvvReg.hasMatch(cvv);
  }

  bool processPayment(PaymentInfo info) {
    if (!validateName(info.name)) return false;
    if (!validateCardNumber(info.cardNumber)) return false;
    if (!validateCvv(info.cvv)) return false;
    // Simulate payment success if all validations pass
    return true;
  }
}

void main() {
  group('PaymentManager', () {
    late PaymentManager manager;

    setUp(() {
      manager = PaymentManager();
    });

    test('should validate correct name', () {
      expect(manager.validateName('John Doe'), true);
    });

    test('should invalidate empty or invalid name', () {
      expect(manager.validateName(''), false);
      expect(manager.validateName('John123'), false);
      expect(manager.validateName('@John!'), false);
    });

    test('should validate correct card number (16 digits only)', () {
      expect(manager.validateCardNumber('1234567812345678'), true);
    });

    test('should invalidate incorrect card numbers', () {
      expect(manager.validateCardNumber('1234'), false);
      expect(manager.validateCardNumber('12345678123456789'), false);
      expect(manager.validateCardNumber('abcd1234abcd1234'), false);
    });

    test('should validate correct CVV (3 digits only)', () {
      expect(manager.validateCvv('123'), true);
    });

    test('should invalidate incorrect CVVs', () {
      expect(manager.validateCvv('12'), false);
      expect(manager.validateCvv('abcd'), false);
      expect(manager.validateCvv('1234'), false);
    });

    test('should process payment successfully for valid inputs', () {
      final info = PaymentInfo(
        name: 'John Doe',
        cardNumber: '1234567812345678',
        cvv: '123',
      );
      expect(manager.processPayment(info), true);
    });

    test('should fail payment if any field invalid', () {
      final info1 = PaymentInfo(
        name: '',
        cardNumber: '1234567812345678',
        cvv: '123',
      );
      expect(manager.processPayment(info1), false);

      final info2 = PaymentInfo(
        name: 'John Doe',
        cardNumber: '1234',
        cvv: '123',
      );
      expect(manager.processPayment(info2), false);

      final info3 = PaymentInfo(
        name: 'John Doe',
        cardNumber: '1234567812345678',
        cvv: '12',
      );
      expect(manager.processPayment(info3), false);
    });
  });
}
