import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/theme/theme.dart';

class BalanceText extends StatefulWidget {
  final bool hiddenBalance;
  final CurrencyState currencyState;
  final AccountState accountState;
  final double offsetFactor;

  const BalanceText({
    super.key,
    required this.hiddenBalance,
    required this.currencyState,
    required this.accountState,
    required this.offsetFactor,
  });

  @override
  State<BalanceText> createState() => _BalanceTextState();
}

class _BalanceTextState extends State<BalanceText> {
  double get startSize => balanceAmountTextStyle.fontSize!;
  double get endSize => startSize - 8.0;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    return TextButton(
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (states) {
            if ({WidgetState.focused, WidgetState.hovered}.any(states.contains)) {
              return themeData.customData.paymentListBgColor;
            }
            return null;
          },
        ),
      ),
      onPressed: () => _changeBtcCurrency(context),
      child: widget.hiddenBalance
          ? Text(
              texts.wallet_dashboard_balance_hide,
              style: balanceAmountTextStyle.copyWith(
                color: themeData.colorScheme.onSecondary,
                fontSize: startSize - (startSize - endSize) * widget.offsetFactor,
              ),
            )
          : RichText(
              text: TextSpan(
                style: balanceAmountTextStyle.copyWith(
                  color: themeData.colorScheme.onSecondary,
                  fontSize: startSize - (startSize - endSize) * widget.offsetFactor,
                ),
                text: widget.currencyState.bitcoinCurrency.format(
                  widget.accountState.walletInfo!.balanceSat.toInt(),
                  removeTrailingZeros: true,
                  includeDisplayName: false,
                ),
                children: [
                  TextSpan(
                    text: " ${widget.currencyState.bitcoinCurrency.displayName}",
                    style: balanceCurrencyTextStyle.copyWith(
                      color: themeData.colorScheme.onSecondary,
                      fontSize: startSize * 0.6 - (startSize * 0.6 - endSize) * widget.offsetFactor,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _changeBtcCurrency(BuildContext context) {
    final userProfileCubit = context.read<UserProfileCubit>();
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;

    if (widget.hiddenBalance == true) {
      userProfileCubit.updateProfile(hideBalance: false);
      return;
    }
    final list = BitcoinCurrency.currencies;
    final index = list.indexOf(
      BitcoinCurrency.fromTickerSymbol(currencyState.bitcoinTicker),
    );
    final nextCurrencyIndex = (index + 1) % list.length;
    if (nextCurrencyIndex == 1) {
      userProfileCubit.updateProfile(hideBalance: true);
    }
    currencyCubit.setBitcoinTicker(list[nextCurrencyIndex].tickerSymbol);
  }
}
