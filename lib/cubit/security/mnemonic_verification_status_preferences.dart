import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Logger _logger = Logger('MnemonicVerificationStatusPreferences');

class MnemonicVerificationStatusPreferences {
  static const bool kDefaultVerificationComplete = false;
  static const String _kVerificationComplete = 'verification_complete';

  static Future<void> setVerificationComplete(bool value, {int maxRetries = 3}) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final bool success = await prefs.setBool(_kVerificationComplete, value);

        if (success) {
          _logger.info('Saved verification complete to SharedPreferences successfully.');
          return;
        } else {
          throw Exception(
            'Failed to save verification complete to SharedPreferences on attempt $attempt.',
          );
        }
      } catch (e, stackTrace) {
        attempt++;
        _logger.warning('Attempt $attempt failed: $e');
        _logger.warning('Stack trace: $stackTrace');

        if (attempt >= maxRetries) {
          _logger.severe('Max retry attempts reached.');
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  static Future<bool> isVerificationComplete() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool result = prefs.getBool(_kVerificationComplete) ?? kDefaultVerificationComplete;
      _logger.info('Retrieved mnemonic verification complete: $result');
      return result;
    } catch (e) {
      _logger.warning('Failed to get mnemonic verification complete from SharedPreferences: $e');
      return false;
    }
  }
}
