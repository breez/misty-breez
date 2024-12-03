import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';

class SatEquivalentLabel extends StatelessWidget {
  final TextEditingController controller;

  const SatEquivalentLabel({
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;

    final ThemeData themeData = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Text(
          getSatoshiValue(currencyState),
          style: themeData.primaryTextTheme.titleSmall!.copyWith(
            fontSize: 18.0,
          ),
        ),
      ),
    );
  }

  String getSatoshiValue(CurrencyState currencyState) {
    final double inputAmount = double.tryParse(controller.text) ?? 0;

    if (inputAmount == 0 || currencyState.fiatConversion() == null) {
      return '0 ${currencyState.bitcoinCurrency.tickerSymbol}';
    }

    final int amountSat = currencyState.fiatConversion()!.fiatToSat(inputAmount);
    final String formattedAmount = currencyState.bitcoinCurrency.format(
      amountSat,
      includeDisplayName: false,
    );

    return '$formattedAmount ${currencyState.bitcoinCurrency.tickerSymbol}';
  }
}
