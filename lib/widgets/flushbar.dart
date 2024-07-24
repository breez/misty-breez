import 'package:another_flushbar/flushbar.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';

Flushbar showFlushbar(
  BuildContext context, {
  String? title,
  Widget? icon,
  bool isDismissible = true,
  bool showMainButton = true,
  String? message,
  Widget? messageWidget,
  String? buttonText,
  FlushbarPosition position = FlushbarPosition.BOTTOM,
  bool Function()? onDismiss,
  Duration duration = const Duration(seconds: 8),
}) {
  final themeData = Theme.of(context);
  final texts = context.texts();

  Flushbar? flush;
  flush = Flushbar(
    isDismissible: isDismissible,
    flushbarPosition: position,
    titleText: title == null
        ? null
        : Text(
            title,
            style: const TextStyle(height: 0.0),
          ),
    icon: icon,
    duration: duration == Duration.zero ? null : duration,
    messageText: messageWidget ??
        Text(
          message ?? texts.flushbar_default_message,
          style: snackBarStyle,
          textAlign: TextAlign.left,
        ),
    backgroundColor: snackBarBackgroundColor,
    mainButton: !showMainButton
        ? null
        : TextButton(
            onPressed: () {
              bool dismiss = onDismiss != null ? onDismiss() : true;
              if (dismiss) {
                flush!.dismiss(true);
              }
            },
            child: Text(
              buttonText ?? texts.flushbar_default_action,
              style: snackBarStyle.copyWith(
                color: themeData.colorScheme.error,
              ),
            ),
          ),
  )..show(context);

  return flush;
}

void popFlushbars(BuildContext context) {
  Navigator.popUntil(context, (route) {
    return route.settings.name != FLUSHBAR_ROUTE_NAME;
  });
}
