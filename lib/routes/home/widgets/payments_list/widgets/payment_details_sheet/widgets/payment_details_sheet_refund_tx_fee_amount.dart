import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/currency.dart';

class PaymentDetailsSheetRefundTxAmount extends StatelessWidget {
  final PaymentData paymentData;
  final AutoSizeGroup? labelAutoSizeGroup;

  const PaymentDetailsSheetRefundTxAmount({
    required this.paymentData,
    super.key,
    this.labelAutoSizeGroup,
  });

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
            style: themeData.primaryTextTheme.headlineMedium?.copyWith(
              fontSize: 18.0,
              color: Colors.white,
            ),
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
                if (paymentData.status == PaymentState.refundPending) {
                  refundTxAmountSat = paymentData.amountSat + paymentData.actualFeeSat;
                }
                final String amountSats = BitcoinCurrency.fromTickerSymbol(
                  state.bitcoinTicker,
                ).format(refundTxAmountSat);
                return Text(
                  paymentData.status == PaymentState.refundPending
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
