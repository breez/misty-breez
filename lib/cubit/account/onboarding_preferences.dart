import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Logger _logger = Logger('OnboardingPreferences');

class OnboardingPreferences {
  static const bool kDefaultOnboardingComplete = false;
  static const String _kOnboardingComplete = 'onboarding_complete';

  static Future<void> setOnboardingComplete(bool value, {int maxRetries = 3}) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final bool success = await prefs.setBool(_kOnboardingComplete, value);

        if (success) {
          _logger.info('Saved isOnboardingComplete to SharedPreferences successfully.');
          return;
        } else {
          throw Exception(
            'Failed to save isOnboardingComplete to SharedPreferences on attempt $attempt.',
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

  static Future<bool> isOnboardingComplete() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool result = prefs.getBool(_kOnboardingComplete) ?? kDefaultOnboardingComplete;
      _logger.info('Retrieved isOnboardingComplete: $result');
      return result;
    } catch (e) {
      _logger.warning('Failed to get isOnboardingComplete from SharedPreferences: $e');
      return false;
    }
  }
}
