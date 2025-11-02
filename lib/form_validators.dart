class FormValidators {
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your full name.';
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email address.';
    if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,}$').hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your phone number.';
    if (!RegExp(r'^[97][0-9]{7}$').hasMatch(value)) {
      return 'Please enter a valid 8-digit phone number. starting with 9 or 7 only';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password.';
    if (value.length < 6 || value.length > 20) {
      return 'Password must be 6-20 characters long.';
    }
    if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter.';
    }
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
      return 'Password must contain at least one number .';
    }
    if (!RegExp(r'(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(value)) {
      return 'Password must contain at least one special character.';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password.';
    if (value != password) return 'Passwords do not match.';
    return null;
  }
}


class LoginValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email address.';
    if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,}$').hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password.';
    return null;
  }
}
