import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/utils/min_font_size.dart';

class TransactionFee extends StatelessWidget {
  final int txFeeSat;

  const TransactionFee({required this.txFeeSat, super.key});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);
    final minFont = MinFontSize(context);

    return ListTile(
      title: AutoSizeText(
        texts.sweep_all_coins_label_transaction_fee,
        style: TextStyle(color: Colors.white.withOpacity(0.4)),
        maxLines: 1,
        minFontSize: minFont.minFontSize,
        stepGranularity: 0.1,
      ),
      trailing: AutoSizeText(
        texts.sweep_all_coins_fee(
          BitcoinCurrency.sat.format(txFeeSat),
        ),
        style: TextStyle(color: themeData.colorScheme.error.withOpacity(0.4)),
        maxLines: 1,
        minFontSize: minFont.minFontSize,
        stepGranularity: 0.1,
      ),
    );
  }
}
