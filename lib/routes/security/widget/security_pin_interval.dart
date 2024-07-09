import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:duration/duration.dart';
import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/bloc/security/security_bloc.dart';
import 'package:l_breez/widgets/preview/preview.dart';

class SecurityPinInterval extends StatelessWidget {
  final Duration interval;

  const SecurityPinInterval({
    super.key,
    required this.interval,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);
    final options = {0, 30, 120, 300, 600, 1800, 3600, interval.inSeconds}.toList();
    options.sort();

    return ListTile(
      title: Text(
        texts.security_and_backup_lock_automatically,
        style: themeData.primaryTextTheme.titleMedium?.copyWith(
          color: Colors.white,
        ),
        maxLines: 1,
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          iconEnabledColor: Colors.white,
          value: interval.inSeconds,
          isDense: true,
          onChanged: (interval) {
            if (interval != null) {
              context.read<SecurityBloc>().setLockInterval(Duration(seconds: interval));
            }
          },
          items: options.map((int seconds) {
            return DropdownMenuItem(
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

  String _formatSeconds(BreezTranslations texts, int seconds) {
    if (seconds == 0) {
      return texts.security_and_backup_lock_automatically_option_immediate;
    }
    // Duration plugin falsely treats country code "cz" as the Czech language code. Issue: https://github.com/desktop-dart/duration/issues/67
    String languageCode = texts.locale == "cs" ? "cz" : texts.locale;
    return prettyDuration(
      Duration(seconds: seconds),
      locale: DurationLocale.fromLanguageCode(languageCode) ?? const EnglishDurationLocale(),
    );
  }
}

void main() {
  runApp(
    const Preview(
      [
        SecurityPinInterval(interval: Duration(seconds: 120)),
      ],
    ),
  );
}
