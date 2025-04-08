import 'package:logging/logging.dart';

final Logger _logger = Logger('EnumUtils');

/// Converts a string or int representation to its corresponding enum value.
///
/// Takes a dynamic [value] (expected to be a String or int) and attempts to match it
/// against the [enumValues] list by comparing their name properties or by index.
///
/// If [value] is not a String or int, or if no matching enum is found, returns the
/// [defaultValue].
///
/// Handles qualified enum names (e.g., 'EnumType.value') by extracting just the
/// value part.
///
/// Example:
/// ```
/// final paymentType = parseEnum(
///   value: 'send',
///   enumValues: PaymentType.values,
///   defaultValue: PaymentType.unknown
/// );
/// ```
///
/// [logFailures] controls whether parsing failures are logged (defaults to false).
T parseEnum<T extends Enum>({
  required dynamic value,
  required List<T> enumValues,
  required T defaultValue,
  bool logFailures = false,
}) {
  // Handle numeric values (index-based)
  if (value is int && value >= 0 && value < enumValues.length) {
    return enumValues[value];
  }

  // Handle String values (name-based)
  if (value is String) {
    // Extract the name part if in format "EnumType.value"
    final String enumName = value.contains('.') ? value.split('.').last : value;

    try {
      return enumValues.firstWhere(
        (T element) => element.name == enumName,
        orElse: () {
          if (logFailures) {
            _logger.warning('Failed to find enum value: $value in ${enumValues.map((T e) => e.name)}');
          }
          return defaultValue;
        },
      );
    } catch (e) {
      if (logFailures) {
        _logger.warning('Error parsing enum value: $value - $e');
      }
    }
  }

  return defaultValue;
}
