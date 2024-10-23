import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_metadata.dart';

class LnUrlPaymentDescription extends StatelessWidget {
  final String metadataText;

  const LnUrlPaymentDescription({super.key, required this.metadataText});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        AutoSizeText(
          texts.utils_print_pdf_header_description,
          style: themeData.primaryTextTheme.headlineMedium?.copyWith(color: Colors.white),
          textAlign: TextAlign.left,
          maxLines: 1,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: LNURLMetadataText(metadataText: metadataText),
        ),
      ],
    );
  }
}