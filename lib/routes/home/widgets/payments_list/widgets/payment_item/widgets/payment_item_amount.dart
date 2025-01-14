import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/theme.dart';

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
              final String amount = currencyState.bitcoinCurrency.format(
                paymentData.amountSat,
                includeDisplayName: false,
              );

              final int actualFeeSat = paymentData.actualFeeSat;
              final String actualFeeFormatted = currencyState.bitcoinCurrency.format(
                actualFeeSat,
                includeDisplayName: false,
              );

              return Column(
                mainAxisAlignment: paymentData.feeSat == 0 || paymentData.status == PaymentState.pending
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  (paymentData.isRefunded)
                      ? const SizedBox.shrink()
                      : Text(
                          hideBalance
                              ? texts.wallet_dashboard_payment_item_balance_hide
                              : paymentData.paymentType == PaymentType.receive
                                  ? texts.wallet_dashboard_payment_item_balance_positive(amount)
                                  : texts.wallet_dashboard_payment_item_balance_negative(amount),
                          style: themeData.paymentItemAmountTextStyle,
                        ),
                  (actualFeeSat == 0 || paymentData.status == PaymentState.pending)
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
