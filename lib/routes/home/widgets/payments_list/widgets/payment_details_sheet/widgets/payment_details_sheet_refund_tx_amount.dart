import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';

class PaymentDetailsSheetRefundTxAmount extends StatelessWidget {
  final PaymentData paymentData;
  final AutoSizeGroup? labelAutoSizeGroup;

  const PaymentDetailsSheetRefundTxAmount({required this.paymentData, super.key, this.labelAutoSizeGroup});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Row(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AutoSizeText(
            texts.payment_details_sheet_refund_tx_amount_label,
            style: themeData.primaryTextTheme.headlineMedium?.copyWith(fontSize: 18.0, color: Colors.white),
            textAlign: TextAlign.left,
            maxLines: 1,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: BlocBuilder<CurrencyCubit, CurrencyState>(
              builder: (BuildContext context, CurrencyState state) {
                int refundTxAmountSat = paymentData.refundTxAmountSat;
                // Calculate the full refund amount (payment + fee) for pending refunds
                // or completed refunds where the refund transaction amount is not tracked
                final bool shouldEstimateRefundAmount =
                    paymentData.status == PaymentState.refundPending ||
                    (paymentData.isRefunded && paymentData.refundTxAmountSat == 0);

                if (shouldEstimateRefundAmount) {
                  refundTxAmountSat = paymentData.amountSat + paymentData.feeSat;
                }
                final String amountSats = BitcoinCurrency.fromTickerSymbol(
                  state.bitcoinTicker,
                ).format(refundTxAmountSat);
                return Text(
                  shouldEstimateRefundAmount
                      ? amountSats
                      : texts.payment_details_dialog_amount_positive(amountSats),
                  style: themeData.primaryTextTheme.displaySmall!.copyWith(
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
