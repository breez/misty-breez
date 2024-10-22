import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/src/theme.dart';

class LnUrlPaymentHeader extends StatelessWidget {
  final String payeeName;
  final int totalAmount;
  final String errorMessage;

  const LnUrlPaymentHeader({
    super.key,
    required this.payeeName,
    required this.totalAmount,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;

    final texts = context.texts();
    final themeData = Theme.of(context);

    return Center(
      child: Column(
        children: [
          Text(
            payeeName,
            style: Theme.of(context).primaryTextTheme.headlineMedium!.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          Text(
            payeeName.isEmpty
                ? texts.payment_request_dialog_requested
                : texts.payment_request_dialog_requesting,
            style: themeData.primaryTextTheme.displaySmall!.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          RichText(
            text: TextSpan(
              style: balanceAmountTextStyle.copyWith(
                color: themeData.colorScheme.onSecondary,
              ),
              text: currencyState.bitcoinCurrency.format(
                totalAmount,
                removeTrailingZeros: true,
                includeDisplayName: false,
              ),
              children: [
                TextSpan(
                  text: " ${currencyState.bitcoinCurrency.displayName}",
                  style: balanceCurrencyTextStyle.copyWith(
                    color: themeData.colorScheme.onSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (errorMessage.isNotEmpty) ...[
            AutoSizeText(
              errorMessage,
              maxLines: 3,
              textAlign: TextAlign.center,
              style: themeData.primaryTextTheme.displaySmall?.copyWith(
                fontSize: 14.3,
                color: themeData.isLightTheme ? Colors.red : themeData.colorScheme.error,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
