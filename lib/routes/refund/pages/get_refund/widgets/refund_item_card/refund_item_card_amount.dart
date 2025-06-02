import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';

class RefundItemCardAmount extends StatelessWidget {
  final int refundTxSat;
  final AutoSizeGroup? labelAutoSizeGroup;

  const RefundItemCardAmount({required this.refundTxSat, this.labelAutoSizeGroup, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    final CurrencyState currencyState = context.read<CurrencyCubit>().state;
    final String amountFormatted = currencyState.bitcoinCurrency.format(refundTxSat);

    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AutoSizeText(
            texts.payment_details_sheet_amount_label,
            style: themeData.primaryTextTheme.headlineMedium?.copyWith(fontSize: 18.0, color: Colors.white),
            textAlign: TextAlign.left,
            maxLines: 1,
            group: labelAutoSizeGroup,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Text(
              amountFormatted,
              style: themeData.primaryTextTheme.displaySmall!.copyWith(fontSize: 18.0, color: Colors.white),
              textAlign: TextAlign.right,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}
