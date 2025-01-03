import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/fiat_conversion.dart';

class FiatBalanceText extends StatelessWidget {
  final bool hiddenBalance;
  final CurrencyState currencyState;
  final AccountState accountState;
  final double offsetFactor;

  const FiatBalanceText({
    required this.hiddenBalance,
    required this.currencyState,
    required this.accountState,
    required this.offsetFactor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    if (!currencyState.fiatEnabled || hiddenBalance || !isAboveMinAmount(currencyState, accountState)) {
      return const SizedBox.shrink();
    }

    return TextButton(
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (<WidgetState>{WidgetState.focused, WidgetState.hovered}.any(states.contains)) {
              return themeData.customData.paymentListBgColor;
            }
            return null;
          },
        ),
      ),
      onPressed: () => _changeFiatCurrency(context),
      child: Text(
        currencyState.fiatConversion()?.format(accountState.walletInfo!.balanceSat.toInt()) ?? '',
        style: balanceFiatConversionTextStyle.copyWith(
          color: themeData.colorScheme.onSecondary.withValues(alpha: pow(1.00 - offsetFactor, 2).toDouble()),
        ),
      ),
    );
  }

  void _changeFiatCurrency(BuildContext context) {
    final FiatConversion? newFiatConversion = nextValidFiatConversion(currencyState, accountState);
    if (newFiatConversion != null) {
      final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
      currencyCubit.setFiatId(newFiatConversion.currencyData.id);
    }
  }

  FiatConversion? nextValidFiatConversion(
    CurrencyState currencyState,
    AccountState accountState,
  ) {
    final double? exchangeRate = currencyState.fiatExchangeRate;
    if (exchangeRate == null) {
      return null;
    }

    final List<String> currencies = currencyState.preferredCurrencies;
    final int currentIndex = currencies.indexOf(currencyState.fiatId);

    final int length = currencies.length;
    for (int i = 1; i < length; i++) {
      final int nextIndex = (i + currentIndex) % length;
      final FiatCurrency? conversion = currencyState.fiatById(currencies[nextIndex]);
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
    final FiatConversion? fiatConversion = currencyState.fiatConversion();
    if (fiatConversion == null) {
      return false;
    }

    final double fiatValue = fiatConversion.satToFiat(accountState.walletInfo!.balanceSat.toInt());
    final int fractionSize = fiatConversion.currencyData.info.fractionSize;
    final double minimumAmount = 1 / pow(10, fractionSize);

    return fiatValue > minimumAmount;
  }
}
