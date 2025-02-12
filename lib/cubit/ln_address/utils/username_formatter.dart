import 'package:flutter/services.dart';

class UsernameInputFormatter extends TextInputFormatter {
  static final RegExp _usernameRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+$',
  );

  static final RegExp _noConsecutiveDotsRegExp = RegExp(
    r'\.\.',
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Check if the username matches the valid characters and does not contain consecutive dots
    if (_usernameRegExp.hasMatch(newValue.text) && !_noConsecutiveDotsRegExp.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue; // Revert to old value if invalid
  }
}

class UsernameFormatter {
  // Example: ".  Satoshi Nakamoto." -> "satoshinakamoto"
  static String sanitize(String rawUsername) {
    if (rawUsername.isEmpty) {
      return '';
    }

    // Ensure no leading or trailing dots
    String sanitized = rawUsername.trim();
    if (sanitized.startsWith('.')) {
      sanitized = sanitized.substring(1);
    }
    if (sanitized.endsWith('.')) {
      sanitized = sanitized.substring(0, sanitized.length - 1);
    }

    return sanitized.toLowerCase().replaceAll(' ', '');
  }

  // Example: "Tomato Elephant" -> "tomatoelephant"
  static String formatDefaultProfileName(String? profileName) {
    return sanitize(profileName ?? '');
  }
}
