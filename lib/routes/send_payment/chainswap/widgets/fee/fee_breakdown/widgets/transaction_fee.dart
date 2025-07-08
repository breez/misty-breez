import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/utils.dart';

class TransactionFee extends StatelessWidget {
  final int txFeeSat;
  final bool nonTransparent;

  const TransactionFee({required this.txFeeSat, this.nonTransparent = false, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);
    final MinFontSize minFont = MinFontSize(context);

    return ListTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          AutoSizeText(
            texts.sweep_all_coins_label_transaction_fee,
            style: themeData.primaryTextTheme.headlineMedium?.copyWith(
              fontSize: 18.0,
              color: Colors.white.withValues(alpha: nonTransparent ? 1 : .4),
            ),
            maxLines: 1,
            minFontSize: minFont.minFontSize,
            stepGranularity: 0.1,
            overflow: TextOverflow.ellipsis,
            group: feeBreakDownLabelGroup,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: AutoSizeText(
                texts.sweep_all_coins_fee(BitcoinCurrency.sat.format(txFeeSat)),
                style: themeData.primaryTextTheme.displaySmall!.copyWith(
                  fontSize: 18.0,
                  color: themeData.colorScheme.error.withValues(alpha: nonTransparent ? 1 : .4),
                  fontWeight: nonTransparent ? FontWeight.w500 : null,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                minFontSize: minFont.minFontSize,
                stepGranularity: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
