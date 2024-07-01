import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';

class LoginText extends StatelessWidget {
  final String domain;

  const LoginText({super.key, required this.domain});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);
    return RichText(
      text: TextSpan(
        style: themeData.dialogTheme.contentTextStyle,
        text: texts.handler_lnurl_login_anonymously,
        children: [
          TextSpan(
            text: domain,
            style: themeData.dialogTheme.contentTextStyle!.copyWith(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: "?",
            style: themeData.dialogTheme.contentTextStyle,
          ),
        ],
      ),
    );
  }
}
