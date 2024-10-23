import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';

class LnUrlPaymentAmount extends StatelessWidget {
  final int amountSat;

  const LnUrlPaymentAmount({super.key, required this.amountSat});

  @override
  Widget build(BuildContext context) {
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;

    final texts = context.texts();
    final themeData = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AutoSizeText(
            texts.send_on_chain_amount,
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
