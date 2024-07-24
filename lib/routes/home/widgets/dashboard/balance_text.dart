import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/theme.dart';

class BalanceText extends StatefulWidget {
  final UserProfileState userProfileState;
  final CurrencyState currencyState;
  final AccountState accountState;
  final double offsetFactor;

  const BalanceText({
    super.key,
    required this.userProfileState,
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

    return widget.userProfileState.profileSettings.hideBalance
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
                widget.accountState.balance,
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
          );
  }
}
