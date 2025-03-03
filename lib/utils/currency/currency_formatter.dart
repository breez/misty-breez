import 'package:intl/intl.dart';
import 'package:intl/number_symbols.dart';
import 'package:intl/number_symbols_data.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('CurrencyFormatter');

/// Base formatter for currency amounts with customizable number formatting
class CurrencyFormatter {
  /// Cached formatter instance for reuse
  final NumberFormat _formatter;

  /// Creates a new CurrencyFormatter with default settings
  CurrencyFormatter() : _formatter = _defineFormatter() {
    _logger.fine('Created CurrencyFormatter instance');
  }

  /// Defines and configures a number formatter with custom spacing
  ///
  /// Returns a configured NumberFormat instance
  static NumberFormat _defineFormatter() {
    // Define a custom symbol set with space as the group separator
    numberFormatSymbols['space-between'] = const NumberSymbols(
      NAME: 'zz',
      DECIMAL_SEP: '.',
      GROUP_SEP: '\u00A0', // Non-breaking space
      PERCENT: '%',
      ZERO_DIGIT: '0',
      PLUS_SIGN: '+',
      MINUS_SIGN: '-',
      EXP_SYMBOL: 'e',
      PERMILL: '\u2030',
      INFINITY: '\u221E',
      NAN: 'NaN',
      DECIMAL_PATTERN: '#,##0.###',
      SCIENTIFIC_PATTERN: '#E0',
      PERCENT_PATTERN: '#,##0%',
      CURRENCY_PATTERN: '\u00A4#,##0.00',
      DEF_CURRENCY_CODE: 'AUD',
    );

    // Create a formatter with the custom symbol set
    final NumberFormat formatter = NumberFormat('###,###.##', 'space-between');
    return formatter;
  }

  /// Gets the number formatter instance
  ///
  /// Returns the configured NumberFormat instance
  NumberFormat getFormatter() {
    return _formatter;
  }

  /// Formats a numeric value according to the formatter's settings
  ///
  /// [value] The numeric value to format
  /// Returns a formatted string representation of the value
  String format(num value) {
    return _formatter.format(value);
  }
}
