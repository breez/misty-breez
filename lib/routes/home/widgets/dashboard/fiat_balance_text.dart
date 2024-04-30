import 'dart:math';

import 'package:l_breez/bloc/account/account_state.dart';
import 'package:l_breez/bloc/currency/currency_bloc.dart';
import 'package:l_breez/bloc/currency/currency_state.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;
import 'package:l_breez/utils/fiat_conversion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FiatBalanceText extends StatefulWidget {
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
  State<FiatBalanceText> createState() => _FiatBalanceTextState();
}

class _FiatBalanceTextState extends State<FiatBalanceText> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return TextButton(
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.focused)) {
            return themeData.customData.paymentListBgColor;
          }
          if (states.contains(WidgetState.hovered)) {
            return themeData.customData.paymentListBgColor;
          }
          return null;
        }),
      ),
      onPressed: () {
        final newFiatConversion = nextValidFiatConversion(
          widget.currencyState,
          widget.accountState,
        );
        if (newFiatConversion != null) {
          context.read<CurrencyBloc>().setFiatId(
                newFiatConversion.currencyData.id,
              );
        }
      },
      child: widget.accountState.balance > 0
          ? Text(
              widget.currencyState.fiatConversion()?.format(widget.accountState.balance) ?? "",
              style: theme.balanceFiatConversionTextStyle.copyWith(
                color: themeData.colorScheme.onSecondary.withOpacity(
                  pow(1.00 - widget.offsetFactor, 2).toDouble(),
                ),
              ),
            )
          : Container(),
    );
  }

  FiatConversion? nextValidFiatConversion(
    CurrencyState currencyState,
    AccountState accountState,
  ) {
    final currencies = currencyState.preferredCurrencies;
    final currentIndex = currencies.indexOf(currencyState.fiatId);
    for (var i = 1; i < currencies.length; i++) {
      final nextIndex = (i + currentIndex) % currencies.length;
      if (isAboveMinAmount(currencyState, accountState)) {
        final conversion = currencyState.fiatById(currencies[nextIndex]);
        final exchangeRate = currencyState.fiatExchangeRate;
        if (conversion != null && exchangeRate != null) {
          return FiatConversion(conversion, exchangeRate);
        }
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
    double minimumAmount = 1 / (pow(10, fractionSize));

    return fiatValue > minimumAmount;
  }
}
