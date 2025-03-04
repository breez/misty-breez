import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

Future<void> promptError(
  BuildContext context, {
  required Widget body,
  String? title,
}) {
  final BreezTranslations texts = context.texts();
  final ThemeData themeData = Theme.of(context);

  final Logger logger = Logger('ErrorDialog');
  final String bodyText = body is Text ? (body).data ?? '' : '';
  logger.info(
    'Showing error dialog - ${title != null ? 'Title: "$title", ' : ''}${bodyText.isNotEmpty ? 'Body: "$bodyText"' : ''}',
  );

  return showDialog<void>(
    useRootNavigator: false,
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0.0),
        title: title == null ? null : Text(title),
        content: SingleChildScrollView(child: body),
        actions: <Widget>[
          TextButton(
            child: Text(
              texts.error_dialog_default_action_ok,
              style: themeData.primaryTextTheme.labelLarge,
            ),
            onPressed: () {
              logger.info('Dialog ${texts.error_dialog_default_action_yes} button pressed');
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<bool?> promptAreYouSure(
  BuildContext context, {
  required Widget body,
  String? title,
}) {
  final BreezTranslations texts = context.texts();
  final ThemeData themeData = Theme.of(context);

  final Logger logger = Logger('AreYouSureDialog');
  final String bodyText = body is Text ? (body).data ?? '' : '';
  logger.info(
    'Showing are you sure dialog - ${title != null ? 'Title: "$title", ' : ''}${bodyText.isNotEmpty ? 'Body: "$bodyText"' : ''}',
  );

  return showDialog<bool>(
    useRootNavigator: false,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0.0),
        title: title == null ? null : Text(title),
        content: SingleChildScrollView(child: body),
        actions: <Widget>[
          TextButton(
            child: Text(
              texts.error_dialog_default_action_no,
              style: themeData.primaryTextTheme.labelLarge,
            ),
            onPressed: () {
              logger.info('Dialog ${texts.error_dialog_default_action_no} button pressed');
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: Text(
              texts.error_dialog_default_action_yes,
              style: themeData.primaryTextTheme.labelLarge,
            ),
            onPressed: () {
              logger.info('Dialog ${texts.error_dialog_default_action_yes} button pressed');
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  );
}
