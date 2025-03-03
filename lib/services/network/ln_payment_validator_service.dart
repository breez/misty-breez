import 'package:logging/logging.dart';

final Logger _logger = Logger('LnPaymentValidatorService');

/// Service for validating Lightning Network payments
class LnPaymentValidatorService {
  /// Private constructor to prevent instantiation
  LnPaymentValidatorService._();

  /// Default Lightning payment validator URL
  static const String defaultValidator = 'https://validate-payment.com/';

  /// Formats a URL for validating a Lightning Network payment
  ///
  /// [invoice] The Lightning invoice to validate
  /// [preimage] The payment preimage
  /// [lnPaymentValidator] Optional custom validator URL
  /// Returns a formatted validation URL
  static String formatValidatorUrl({
    required String invoice,
    required String preimage,
    String lnPaymentValidator = defaultValidator,
  }) {
    _logger.fine('Formatting validation URL for invoice: ${invoice.substring(0, 10)}...');
    return '$lnPaymentValidator/?invoice=$invoice&preimage=$preimage';
  }

  /// Checks if an invoice format is valid
  ///
  /// [invoice] The Lightning invoice to validate
  /// Returns true if the invoice format is valid
  static bool isValidInvoiceFormat(String invoice) {
    // Check if the invoice starts with 'lnbc' or 'lntb' (mainnet or testnet)
    return invoice.toLowerCase().startsWith('lnbc') || invoice.toLowerCase().startsWith('lntb');
  }
}
