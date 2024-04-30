import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/bloc/currency/currency_bloc.dart';
import 'package:l_breez/bloc/currency/currency_state.dart';
import 'package:l_breez/bloc/user_profile/user_profile_bloc.dart';
import 'package:l_breez/bloc/user_profile/user_profile_state.dart';
import 'package:l_breez/models/payment_minutiae.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;
import 'package:l_breez/theme/theme_provider.dart';

class PaymentItemAmount extends StatelessWidget {
  final PaymentMinutiae _paymentMinutiae;

  const PaymentItemAmount(this._paymentMinutiae, {super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final texts = context.texts();

    return SizedBox(
      height: 44,
      child: BlocBuilder<UserProfileBloc, UserProfileState>(builder: (context, userModel) {
        final bool hideBalance = userModel.profileSettings.hideBalance;
        return BlocBuilder<CurrencyBloc, CurrencyState>(
          builder: (context, currencyState) {
            final fee = _paymentMinutiae.feeSat;
            final amount = currencyState.bitcoinCurrency.format(
              _paymentMinutiae.amountSat,
              includeDisplayName: false,
            );
            final feeFormatted = currencyState.bitcoinCurrency.format(
              fee,
              includeDisplayName: false,
            );

            return Column(
              mainAxisAlignment:
                  _paymentMinutiae.feeSat == 0 || _paymentMinutiae.status == PaymentState.pending
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hideBalance
                      ? texts.wallet_dashboard_payment_item_balance_hide
                      : _paymentMinutiae.paymentType == PaymentType.receive
                          ? texts.wallet_dashboard_payment_item_balance_positive(amount)
                          : texts.wallet_dashboard_payment_item_balance_negative(amount),
                  style: themeData.paymentItemAmountTextStyle,
                ),
                (fee == 0 || _paymentMinutiae.status == PaymentState.pending)
                    ? const SizedBox()
                    : Text(
                        hideBalance
                            ? texts.wallet_dashboard_payment_item_balance_hide
                            : texts.wallet_dashboard_payment_item_balance_fee(feeFormatted),
                        style: themeData.paymentItemFeeTextStyle,
                      ),
              ],
            );
          },
        );
      }),
    );
  }
}
