import 'dart:io';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';

class BetaWarningDialog extends StatefulWidget {
  const BetaWarningDialog({super.key});

  @override
  BetaWarningDialogState createState() => BetaWarningDialogState();
}

class BetaWarningDialogState extends State<BetaWarningDialog> {
  bool _isUnderstood = false;
  bool _showReminderText = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Theme(
      data: themeData.copyWith(unselectedWidgetColor: themeData.canvasColor),
      child: AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24.0, 22.0, 0.0, 16.0),
        title: Text(texts.beta_warning_title),
        contentPadding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 24.0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _getContent(context),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => exit(0),
            child: Text(texts.beta_warning_action_exit, style: themeData.primaryTextTheme.labelLarge),
          ),
          TextButton(
            onPressed: (() {
              if (_isUnderstood) {
                Navigator.of(context).pop(_isUnderstood);
              } else {
                setState(() {
                  _showReminderText = !_isUnderstood;
                });
              }
            }),
            child: Text(texts.beta_warning_action_continue, style: themeData.primaryTextTheme.labelLarge),
          ),
        ],
      ),
    );
  }

  List<Widget> _getContent(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return <Widget>[
      Padding(
        padding: const EdgeInsets.only(left: 15.0, right: 12.0),
        child: Text(
          texts.beta_warning_message,
          style: themeData.primaryTextTheme.displaySmall!.copyWith(fontSize: 16),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Row(
          children: <Widget>[
            Theme(
              data: themeData.copyWith(unselectedWidgetColor: themeData.textTheme.labelLarge!.color),
              child: Checkbox(
                activeColor: themeData.canvasColor,
                value: _isUnderstood,
                onChanged: (bool? value) {
                  setState(() {
                    _isUnderstood = value == true;
                  });
                },
              ),
            ),
            Text(
              texts.beta_warning_understand,
              style: themeData.primaryTextTheme.displaySmall!.copyWith(fontSize: 16),
            ),
          ],
        ),
      ),
      Visibility(
        visible: _showReminderText,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
          child: Text(
            texts.beta_warning_understand_confirmation,
            style: themeData.primaryTextTheme.displaySmall!
                .copyWith(fontSize: 16)
                .copyWith(fontSize: 12.0, color: Colors.red),
          ),
        ),
      ),
    ];
  }
}
