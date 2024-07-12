import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/utils/min_font_size.dart';

class BoltzServiceFee extends StatelessWidget {
  final int boltzServiceFee;

  const BoltzServiceFee({required this.boltzServiceFee, super.key});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);
    final minFont = MinFontSize(context);

    return ListTile(
      title: AutoSizeText(
        texts.reverse_swap_confirmation_boltz_fee,
        style: TextStyle(color: Colors.white.withOpacity(0.4)),
        maxLines: 1,
        minFontSize: minFont.minFontSize,
        stepGranularity: 0.1,
      ),
      trailing: AutoSizeText(
        texts.reverse_swap_confirmation_boltz_fee_value(
          BitcoinCurrency.sat.format(boltzServiceFee),
        ),
        style: TextStyle(color: themeData.colorScheme.error.withOpacity(0.4)),
        maxLines: 1,
        minFontSize: minFont.minFontSize,
        stepGranularity: 0.1,
      ),
    );
  }
}
