import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy/form_validators.dart';
void main() {
  group('validateEmail', () {
    test('should return error if email is empty', () {
      expect(
        LoginValidators.validateEmail(''),
        'Please enter your email address.',
      );
    });

    test('should return error if email is invalid', () {
      expect(
        LoginValidators.validateEmail('invalid-email'),
        'Please enter a valid email address.',
      );
    });

    test('should return null if email is valid', () {
      expect(
        LoginValidators.validateEmail('test@example.com'),
        null,
      );
    });
  });

  group('validatePassword', () {
    test('should return error if password is empty', () {
      expect(
        LoginValidators.validatePassword(''),
        'Please enter your password.',
      );
    });

    test('should return null if password is provided', () {
      expect(
        LoginValidators.validatePassword('somepassword'),
        null,
      );
    });
  });
}
