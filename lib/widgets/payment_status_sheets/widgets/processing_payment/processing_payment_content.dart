import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/widgets.dart';

class ProcessingPaymentContent extends StatelessWidget {
  final Color color;

  const ProcessingPaymentContent({
    super.key,
    this.color = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);
    final CustomData customData = themeData.customData;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            texts.processing_payment_dialog_processing_payment,
            style: themeData.dialogTheme.titleTextStyle!.copyWith(
              fontSize: 24.0,
              color: themeData.isLightTheme ? null : Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            height: 64.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                LoadingAnimatedText(
                  loadingMessage: texts.processing_payment_dialog_wait,
                  textStyle: themeData.dialogTheme.contentTextStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Image.asset(
          customData.loaderAssetPath,
          height: 64.0,
          colorBlendMode: customData.loaderColorBlendMode,
          color: color,
          gaplessPlayback: true,
        ),
      ],
    );
  }
}
