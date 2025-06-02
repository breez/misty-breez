import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/theme/theme.dart';

class PaymentItemAmount extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentItemAmount(this.paymentData, {super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final BreezTranslations texts = context.texts();

    return SizedBox(
      height: 44,
      child: BlocBuilder<UserProfileCubit, UserProfileState>(
        builder: (BuildContext context, UserProfileState userModel) {
          final bool hideBalance = userModel.profileSettings.hideBalance;

          return BlocBuilder<CurrencyCubit, CurrencyState>(
            builder: (BuildContext context, CurrencyState currencyState) {
              int amountSat = paymentData.amountSat;
              int actualFeeSat = paymentData.actualFeeSat;

              // Calculate the full refund amount (payment + fee) for pending refunds
              // or completed refunds where the refund transaction amount is not tracked
              // and then display it on Amount Widget with hidden fees
              final bool shouldEstimateRefundAmount =
                  paymentData.status == PaymentState.refundPending ||
                  (paymentData.isRefunded && paymentData.refundTxAmountSat == 0);

              if (shouldEstimateRefundAmount) {
                amountSat = paymentData.amountSat + paymentData.feeSat;
                // Hide fees
                actualFeeSat = 0;
              }

              final String amountFormatted = currencyState.bitcoinCurrency.format(
                amountSat,
                includeDisplayName: false,
              );

              final String actualFeeFormatted = currencyState.bitcoinCurrency.format(
                actualFeeSat,
                includeDisplayName: false,
              );

              final bool isPending =
                  paymentData.status == PaymentState.pending ||
                  paymentData.status == PaymentState.refundPending;

              return Column(
                mainAxisAlignment: (actualFeeSat == 0 || isPending)
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  // Amount widget
                  Text(
                    hideBalance
                        ? texts.wallet_dashboard_payment_item_balance_hide
                        : shouldEstimateRefundAmount
                        ? amountFormatted
                        : paymentData.paymentType == PaymentType.receive
                        ? texts.wallet_dashboard_payment_item_balance_positive(amountFormatted)
                        : texts.wallet_dashboard_payment_item_balance_negative(amountFormatted),
                    style: themeData.paymentItemAmountTextStyle,
                  ),
                  // Fee widget
                  (actualFeeSat == 0 || isPending)
                      ? const SizedBox.shrink()
                      : Text(
                          hideBalance
                              ? texts.wallet_dashboard_payment_item_balance_hide
                              : texts.wallet_dashboard_payment_item_balance_fee(actualFeeFormatted),
                          style: themeData.paymentItemFeeTextStyle,
                        ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
