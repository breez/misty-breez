import 'package:flutter/services.dart';

class UsernameInputFormatter extends TextInputFormatter {
  // Loosely comply with email standards, namely RFC 5322
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String formatted = newValue.text.trim();

    // Remove invalid characters
    formatted = formatted.replaceAll(
      RegExp(r"[^a-zA-Z0-9!#$%&'*+/=?^_`{|}~.-]"),
      '',
    );

    // Prevent consecutive dots (but allow trailing dots during typing)
    formatted = formatted.replaceAll(RegExp(r'\.\.+'), '.');

    return TextEditingValue(
      text: formatted,
      selection: newValue.selection,
    );
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

    return sanitized;
  }

  // Example: "Tomato Elephant" -> "tomatoelephant"
  static String formatDefaultProfileName(String? profileName) {
    return sanitize(profileName ?? '');
  }
}
