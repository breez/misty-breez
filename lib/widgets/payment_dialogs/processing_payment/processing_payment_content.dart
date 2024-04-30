import 'package:breez_translations/breez_translations_locales.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;
import 'package:l_breez/widgets/loading_animated_text.dart';
import 'package:l_breez/widgets/payment_dialogs/processing_payment/processing_payment_title.dart';
import 'package:flutter/material.dart';

class ProcessingPaymentContent extends StatelessWidget {
  final GlobalKey? dialogKey;
  final Color color;

  const ProcessingPaymentContent({
    super.key,
    this.dialogKey,
    this.color = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);
    final customData = themeData.customData;
    final queryData = MediaQuery.of(context);

    return SingleChildScrollView(
      child: Column(
        key: dialogKey,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          const ProcessingPaymentTitle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
            child: SizedBox(
              width: queryData.size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingAnimatedText(
                    loadingMessage: texts.processing_payment_dialog_wait,
                    textStyle: themeData.dialogTheme.contentTextStyle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Image.asset(
              customData.loaderAssetPath,
              height: 64.0,
              colorBlendMode: customData.loaderColorBlendMode,
              color: color,
              gaplessPlayback: true,
            ),
          ),
        ],
      ),
    );
  }
}
