class Validators {
  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? name(String? value, String label) {
    final missing = required(value, label);
    if (missing != null) return missing;
    if (!RegExp(r"^[A-Za-z][A-Za-z .'-]*$").hasMatch(value!.trim())) {
      return '$label may only contain letters';
    }
    return null;
  }

  static String? age(String? value) {
    final missing = required(value, 'Age');
    if (missing != null) return missing;
    final age = int.tryParse(value!.trim());
    if (age == null || age < 1 || age > 120) return 'Enter a valid age (1-120)';
    return null;
  }

  static String? contactNo(String? value) {
    final missing = required(value, 'Contact number');
    if (missing != null) return missing;
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(value!.trim())) {
      return 'Enter 7-15 digits (optional leading +)';
    }
    return null;
  }

  static String? username(String? value) {
    final missing = required(value, 'Username');
    if (missing != null) return missing;
    if (!RegExp(r'^[A-Za-z0-9_.]{3,20}$').hasMatch(value!.trim())) {
      return '3-20 characters: letters, numbers, _ or .';
    }
    return null;
  }

  static String? email(String? value) {
    final missing = required(value, 'Email address');
    if (missing != null) return missing;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add an uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Add a lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Add a number';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) return 'Add a special character';
    return null;
  }
}
