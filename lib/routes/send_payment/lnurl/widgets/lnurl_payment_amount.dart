import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';

class LnPaymentAmount extends StatelessWidget {
  final int amountSat;

  const LnPaymentAmount({required this.amountSat, super.key});

  @override
  Widget build(BuildContext context) {
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;

    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AutoSizeText(
            texts.ln_payment_amount_label,
            style: themeData.primaryTextTheme.headlineMedium?.copyWith(color: Colors.white),
            textAlign: TextAlign.left,
            maxLines: 1,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: AutoSizeText(
              currencyState.bitcoinCurrency.format(amountSat),
              style: TextStyle(color: themeData.colorScheme.error),
              textAlign: TextAlign.right,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}
