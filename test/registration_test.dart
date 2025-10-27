import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy/form_validators.dart';

void main() {
  group('validateFullName', () {
    test('should return error if full name is empty', () {
      expect(
        FormValidators.validateFullName(''),
        'Please enter your full name.',
      );
    });

    test('should return null if full name is valid', () {
      expect(
        FormValidators.validateFullName('John Doe'),
        null,
      );
    });
  });

  group('validateEmail', () {
    test('should return error if email is empty', () {
      expect(
        FormValidators.validateEmail(''),
        'Please enter your email address.',
      );
    });

    test('should return error if email is invalid', () {
      expect(
        FormValidators.validateEmail('invalid-email'),
        'Please enter a valid email address.',
      );
    });

    test('should return null if email is valid', () {
      expect(
        FormValidators.validateEmail('test@example.com'),
        null,
      );
    });
  });

  group('validatePhoneNumber', () {
    test('should return error if phone number is empty', () {
      expect(
        FormValidators.validatePhoneNumber(''),
        'Please enter your phone number.',
      );
    });

    test('should return error if phone number is invalid', () {
      expect(
        FormValidators.validatePhoneNumber('12345678'),
        'Please enter a valid 8-digit phone number. starting with 9 or 7 only',
      );
    });

    test('should return null if phone number is valid', () {
      expect(
        FormValidators.validatePhoneNumber('91234567'),
        null,
      );
    });
  });

  group('validatePassword', () {
    test('should return error if password is empty', () {
      expect(
        FormValidators.validatePassword(''),
        'Please enter a password.',
      );
    });

    test('should return null if password is valid', () {
      expect(
        FormValidators.validatePassword('Abcdef1!'),
        null,
      );
    });
  });

  group('validateConfirmPassword', () {
    test('should return error if confirm password is empty', () {
      expect(
        FormValidators.validateConfirmPassword('', 'Password1!'),
        'Please confirm your password.',
      );
    });

    test('should return error if passwords do not match', () {
      expect(
        FormValidators.validateConfirmPassword('Wrong1!', 'Password1!'),
        'Passwords do not match.',
      );
    });

    test('should return null if passwords match', () {
      expect(
        FormValidators.validateConfirmPassword('Password1!', 'Password1!'),
        null,
      );
    });
  });
}
