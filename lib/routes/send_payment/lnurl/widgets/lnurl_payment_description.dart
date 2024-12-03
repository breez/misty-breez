import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/widgets/widgets.dart';

class LnPaymentDescription extends StatelessWidget {
  final String metadataText;

  const LnPaymentDescription({required this.metadataText, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AutoSizeText(
          texts.ln_payment_description_label,
          style: themeData.primaryTextTheme.headlineMedium?.copyWith(
            fontSize: 18.0,
            color: Colors.white,
          ),
          textAlign: TextAlign.left,
          maxLines: 1,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: WarningBox(
            boxPadding: EdgeInsets.zero,
            backgroundColor: themeData.primaryColorLight.withOpacity(0.1),
            borderColor: themeData.primaryColorLight.withOpacity(0.7),
            child: LNURLMetadataText(metadataText: metadataText),
          ),
        ),
      ],
    );
  }
}
