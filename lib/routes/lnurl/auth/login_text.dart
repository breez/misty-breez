import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';

class LoginText extends StatelessWidget {
  final String domain;

  const LoginText({required this.domain, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);
    return RichText(
      text: TextSpan(
        style: themeData.dialogTheme.contentTextStyle,
        text: texts.handler_lnurl_login_anonymously,
        children: <InlineSpan>[
          TextSpan(
            text: domain,
            style: themeData.dialogTheme.contentTextStyle!.copyWith(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: '?', style: themeData.dialogTheme.contentTextStyle),
        ],
      ),
    );
  }
}
