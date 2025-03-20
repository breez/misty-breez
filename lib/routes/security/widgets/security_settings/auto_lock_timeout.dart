import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/routes/security/services/auth_service.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('SecurityInterval');

/// A widget for selecting the auto-lock interval
class AutoLockTimeout extends StatelessWidget {
  /// The current auto-lock interval
  final Duration interval;

  /// Creates a security interval selector
  ///
  /// [interval] The current auto-lock interval
  const AutoLockTimeout({
    required this.interval,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    // Default options plus the current interval
    final List<int> options = <int>{0, 30, 120, 300, 600, 1800, 3600, interval.inSeconds}.toList();

    options.sort();

    return ListTile(
      title: Text(
        texts.security_and_backup_lock_automatically,
        style: themeData.primaryTextTheme.titleMedium?.copyWith(
          color: Colors.white,
        ),
        maxLines: 1,
      ),
      trailing: _buildIntervalDropdown(context, themeData, options, texts),
    );
  }

  /// Builds the dropdown for interval selection
  Widget _buildIntervalDropdown(
    BuildContext context,
    ThemeData themeData,
    List<int> options,
    BreezTranslations texts,
  ) {
    return Theme(
      data: themeData.copyWith(
        canvasColor: themeData.customData.paymentListBgColor,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          iconEnabledColor: Colors.white,
          value: interval.inSeconds,
          isDense: true,
          onChanged: (int? newInterval) => _onIntervalChanged(context, newInterval),
          items: options.map((int seconds) {
            return DropdownMenuItem<int>(
              value: seconds,
              child: Text(
                _formatSeconds(texts, seconds),
                style: themeData.primaryTextTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
                maxLines: 1,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Handles interval change
  Future<void> _onIntervalChanged(BuildContext context, int? intervalSeconds) async {
    if (intervalSeconds != null) {
      _logger.info('Changing auto-lock interval to $intervalSeconds seconds');
      final AuthService authService = AuthService(context: context);
      await authService.updateAutoLockTimeout(Duration(seconds: intervalSeconds));
    }
  }

  /// Formats seconds into a human-readable string
  String _formatSeconds(BreezTranslations texts, int seconds) {
    if (seconds == 0) {
      return texts.security_and_backup_lock_automatically_option_immediate;
    }

    // Duration plugin falsely treats country code "cz" as the Czech language code.
    // Issue: https://github.com/desktop-dart/duration/issues/67
    final String languageCode = texts.locale == 'cs' ? 'cz' : texts.locale;

    return prettyDuration(
      Duration(seconds: seconds),
      locale: DurationLocale.fromLanguageCode(languageCode) ?? const EnglishDurationLocale(),
    );
  }
}
