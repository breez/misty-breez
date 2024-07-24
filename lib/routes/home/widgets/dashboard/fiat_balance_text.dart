import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/fiat_conversion.dart';

class FiatBalanceText extends StatelessWidget {
  final CurrencyState currencyState;
  final AccountState accountState;
  final double offsetFactor;

  const FiatBalanceText({
    super.key,
    required this.currencyState,
    required this.accountState,
    required this.offsetFactor,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    if (accountState.balance <= 0) {
      return const SizedBox.shrink();
    }

    return TextButton(
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if (states.contains(WidgetState.focused) || states.contains(WidgetState.hovered)) {
              return themeData.customData.paymentListBgColor;
            }
            return null;
          },
        ),
      ),
      onPressed: () => _changeFiatCurrency(context),
      child: Text(
        currencyState.fiatConversion()?.format(accountState.balance) ?? "",
        style: balanceFiatConversionTextStyle.copyWith(
          color: themeData.colorScheme.onSecondary.withOpacity(pow(1.00 - offsetFactor, 2).toDouble()),
        ),
      ),
    );
  }

  void _changeFiatCurrency(BuildContext context) {
    final newFiatConversion = nextValidFiatConversion(currencyState, accountState);
    if (newFiatConversion != null) {
      final currencyCubit = context.read<CurrencyCubit>();
      currencyCubit.setFiatId(newFiatConversion.currencyData.id);
    }
  }

  FiatConversion? nextValidFiatConversion(
    CurrencyState currencyState,
    AccountState accountState,
  ) {
    final exchangeRate = currencyState.fiatExchangeRate;
    if (exchangeRate == null) return null;

    final currencies = currencyState.preferredCurrencies;
    final currentIndex = currencies.indexOf(currencyState.fiatId);

    final length = currencies.length;
    for (var i = 1; i < length; i++) {
      final nextIndex = (i + currentIndex) % length;
      final conversion = currencyState.fiatById(currencies[nextIndex]);
      if (conversion != null && isAboveMinAmount(currencyState, accountState)) {
        return FiatConversion(conversion, exchangeRate);
      }
    }
    return null;
  }

  bool isAboveMinAmount(
    CurrencyState currencyState,
    AccountState accountState,
  ) {
    final fiatConversion = currencyState.fiatConversion();
    if (fiatConversion == null) return false;

    double fiatValue = fiatConversion.satToFiat(accountState.balance);
    int fractionSize = fiatConversion.currencyData.info.fractionSize;
    double minimumAmount = 1 / pow(10, fractionSize);

    return fiatValue > minimumAmount;
  }
}
