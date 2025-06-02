import 'package:logging/logging.dart';

final Logger _logger = Logger('JsonParsingUtils');

/// Utility functions for parsing JSON values
class JsonParsingUtils {
  /// Parses a dynamic value to BigInt, handling both string and integer inputs
  /// If [defaultValue] is not provided, BigInt.zero will be used as default
  static BigInt parseToBigInt(dynamic value, {required String fieldName, BigInt? defaultValue}) {
    final BigInt defaultVal = defaultValue ?? BigInt.zero;

    try {
      if (value == null) {
        return defaultVal;
      } else if (value is String) {
        return BigInt.parse(value);
      } else if (value is int) {
        return BigInt.from(value);
      } else if (value is BigInt) {
        return value;
      } else {
        _logger.warning('Invalid type for BigInt field $fieldName: ${value.runtimeType}');
        return defaultVal;
      }
    } catch (e, stack) {
      _logger.severe('Error parsing BigInt from $value for field $fieldName: $e\n$stack');
      return defaultVal;
    }
  }

  /// Parses a dynamic value to int, handling both string and integer inputs
  /// If [defaultValue] is not provided, 0 will be used as default
  static int parseToInt(dynamic value, {required String fieldName, int? defaultValue}) {
    final int defaultVal = defaultValue ?? 0;

    try {
      if (value == null) {
        return defaultVal;
      } else if (value is String) {
        return int.parse(value);
      } else if (value is int) {
        return value;
      } else {
        _logger.warning('Invalid type for int field $fieldName: ${value.runtimeType}');
        return defaultVal;
      }
    } catch (e, stack) {
      _logger.severe('Error parsing int from $value for field $fieldName: $e\n$stack');
      return defaultVal;
    }
  }
}
