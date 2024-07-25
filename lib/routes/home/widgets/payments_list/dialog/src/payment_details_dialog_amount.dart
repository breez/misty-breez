import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/models/payment_minutiae.dart';

class PaymentDetailsDialogAmount extends StatelessWidget {
  final PaymentMinutiae paymentMinutiae;
  final AutoSizeGroup? labelAutoSizeGroup;
  final AutoSizeGroup? valueAutoSizeGroup;

  const PaymentDetailsDialogAmount({
    super.key,
    required this.paymentMinutiae,
    this.labelAutoSizeGroup,
    this.valueAutoSizeGroup,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    return Container(
      height: 36.0,
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: AutoSizeText(
              texts.payment_details_dialog_amount_title,
              style: themeData.primaryTextTheme.headlineMedium,
              textAlign: TextAlign.left,
              maxLines: 1,
              group: labelAutoSizeGroup,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: BlocBuilder<CurrencyCubit, CurrencyState>(builder: (context, state) {
                final amountSats = BitcoinCurrency.fromTickerSymbol(
                  state.bitcoinTicker,
                ).format(paymentMinutiae.amountSat);
                return AutoSizeText(
                  paymentMinutiae.paymentType == PaymentType.receive
                      ? texts.payment_details_dialog_amount_positive(amountSats)
                      : texts.payment_details_dialog_amount_negative(amountSats),
                  style: themeData.primaryTextTheme.displaySmall,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  group: valueAutoSizeGroup,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
