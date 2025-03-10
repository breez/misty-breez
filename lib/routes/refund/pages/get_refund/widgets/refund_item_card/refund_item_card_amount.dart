import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';

class RefundItemCardAmount extends StatelessWidget {
  final int refundTxSat;

  const RefundItemCardAmount({required this.refundTxSat, super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    final CurrencyState currencyState = context.read<CurrencyCubit>().state;
    final String amountFormatted = currencyState.bitcoinCurrency.format(refundTxSat);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            texts.ln_payment_amount_label,
            style: themeData.primaryTextTheme.headlineMedium?.copyWith(
              fontSize: 18.0,
              color: Colors.white,
            ),
          ),
          Text(
            amountFormatted,
            style: themeData.primaryTextTheme.displaySmall!.copyWith(
              fontSize: 18.0,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
