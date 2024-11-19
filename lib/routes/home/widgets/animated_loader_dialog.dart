import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/loading_animated_text.dart';

AlertDialog createAnimatedLoaderDialog(
  BuildContext context,
  String text, {
  bool withOKButton = true,
}) {
  final ThemeData themeData = Theme.of(context);
  final BreezTranslations texts = context.texts();
  final NavigatorState navigator = Navigator.of(context);

  return AlertDialog(
    contentPadding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0),
    content: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LoadingAnimatedText(
          loadingMessage: text,
          textStyle: themeData.dialogTheme.contentTextStyle,
          textAlign: TextAlign.center,
        ),
        Image.asset(
          themeData.customData.loaderAssetPath,
          height: 64.0,
          gaplessPlayback: true,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: withOKButton
              ? <Widget>[
                  TextButton(
                    child: Text(
                      texts.backup_in_progress_action_confirm,
                      style: themeData.primaryTextTheme.labelLarge,
                    ),
                    onPressed: () => navigator.pop(),
                  ),
                ]
              : <Widget>[],
        ),
      ],
    ),
  );
}
