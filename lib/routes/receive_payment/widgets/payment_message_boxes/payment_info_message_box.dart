import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/services/services.dart';
import 'package:misty_breez/widgets/widgets.dart';

class PaymentInfoMessageBox extends StatelessWidget {
  final String message;
  final String? linkUrl;

  const PaymentInfoMessageBox({required this.message, this.linkUrl, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return WarningBox(
      boxPadding: EdgeInsets.zero,
      backgroundColor: themeData.colorScheme.error.withValues(alpha: .1),
      contentPadding: const EdgeInsets.all(16.0),
      child: linkUrl != null
          ? RichText(
              text: TextSpan(
                text: message,
                style: themeData.textTheme.titleLarge?.copyWith(color: themeData.colorScheme.error),
                children: <InlineSpan>[
                  TextSpan(
                    text: 'here',
                    style: themeData.textTheme.titleLarge?.copyWith(
                      color: themeData.colorScheme.error,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => ExternalBrowserService.launchLink(context, linkAddress: linkUrl!),
                  ),
                  TextSpan(
                    text: '.',
                    style: themeData.textTheme.titleLarge?.copyWith(color: themeData.colorScheme.error),
                  ),
                ],
              ),
            )
          : Text(
              message,
              style: themeData.textTheme.titleLarge?.copyWith(color: themeData.colorScheme.error),
            ),
    );
  }
}
