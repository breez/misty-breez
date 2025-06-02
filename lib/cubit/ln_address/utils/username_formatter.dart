import 'dart:collection';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/services.dart';

/// A formatter for validating and formatting usernames in text input fields.
///
/// This formatter ensures that usernames only contain valid characters
/// and follow specific formatting rules (no consecutive dots, etc.).
class UsernameInputFormatter extends TextInputFormatter {
  /// Regular expression for valid username characters: letters, numbers, and certain symbols
  static final RegExp _validCharRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+$');

  /// Regular expression to detect consecutive dots
  static final RegExp _consecutiveDotsRegExp = RegExp(r'\.\.');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Fix for backspace bug: Always allow deletion operations
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    // Validate the input for allowed characters and formatting rules
    if (_isValidUsername(newValue.text)) {
      return newValue;
    } else {
      return oldValue;
    }
  }

  /// Validates if the given string follows username formatting rules.
  ///
  /// Returns true if the username contains only valid characters
  /// and does not contain consecutive dots.
  bool _isValidUsername(String username) {
    return _validCharRegExp.hasMatch(username) && !_consecutiveDotsRegExp.hasMatch(username);
  }
}

/// Utility class for sanitizing and formatting usernames.
///
/// Provides methods to clean and format raw username strings for storage
/// and display, following consistent username rules.
class UsernameFormatter {
  /// Cache size for sanitized usernames
  static const int _maxCacheSize = 100;

  /// LRU cache for sanitized usernames
  static final LinkedHashMap<String, String> _sanitizeCache = LinkedHashMap<String, String>();

  /// Sanitizes a raw username by removing invalid characters and formatting.
  ///
  /// Performs the following operations:
  /// - Trims leading and trailing whitespace
  /// - Removes leading and trailing dots
  /// - Converts to lowercase
  /// - Removes all spaces
  ///
  /// Example: ".  Satoshi Nakamoto." -> "satoshinakamoto"
  ///
  /// Returns an empty string if the input is empty.
  static String sanitize(String rawUsername) {
    if (rawUsername.isEmpty) {
      return '';
    }

    // Check cache first
    if (_sanitizeCache.containsKey(rawUsername)) {
      // Move this entry to the end (most recently used)
      final String value = _sanitizeCache.remove(rawUsername)!;
      _sanitizeCache[rawUsername] = value;
      return value;
    }

    try {
      // Create a sanitized version following username rules
      String sanitized = rawUsername.trim();

      // Remove diacritics
      sanitized = removeDiacritics(sanitized);

      // Remove leading and trailing dots
      sanitized = _removeLeadingTrailingDots(sanitized);

      // Convert to lowercase and remove spaces
      sanitized = sanitized.toLowerCase().replaceAll(' ', '');

      // Cache the result
      _addToCache(rawUsername, sanitized);

      return sanitized;
    } catch (e) {
      return '';
    }
  }

  /// Adds a key-value pair to the cache, managing its size.
  ///
  /// If the cache is at capacity, removes the least recently used entry.
  static void _addToCache(String key, String value) {
    if (_sanitizeCache.length >= _maxCacheSize) {
      // Remove least recently used (first key)
      _sanitizeCache.remove(_sanitizeCache.keys.first);
    }
    _sanitizeCache[key] = value;
  }

  /// Efficiently removes leading and trailing dots from a string.
  static String _removeLeadingTrailingDots(String input) {
    if (input.isEmpty) {
      return input;
    }

    String result = input;
    // Remove leading dots
    while (result.isNotEmpty && result.startsWith('.')) {
      result = result.substring(1);
    }

    // Remove trailing dots
    while (result.isNotEmpty && result.endsWith('.')) {
      result = result.substring(0, result.length - 1);
    }

    return result;
  }

  /// Formats a default profile name according to username rules.
  ///
  /// Takes a potential null input and sanitizes it for use as a username.
  ///
  /// Example: "Tomato Elephant" -> "tomatoelephant"
  ///
  /// Returns an empty string if input is null or empty.
  static String formatDefaultProfileName(String? defaultProfileName) {
    final String nameToFormat = defaultProfileName ?? '';

    return sanitize(nameToFormat);
  }

  /// Clears the username sanitization cache.
  ///
  /// Can be called to free memory when the cache is no longer needed.
  static void clearCache() {
    _sanitizeCache.clear();
  }
}
