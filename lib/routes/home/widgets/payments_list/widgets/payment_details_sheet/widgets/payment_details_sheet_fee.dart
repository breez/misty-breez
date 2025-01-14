import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/models/payment_details_extension.dart';

class PaymentDetailsSheetFee extends StatelessWidget {
  final PaymentData paymentData;
  final AutoSizeGroup? labelAutoSizeGroup;

  const PaymentDetailsSheetFee({
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
            texts.ln_payment_fee_label,
            style: themeData.primaryTextTheme.headlineMedium?.copyWith(
              fontSize: 18.0,
              color: Colors.white,
            ),
            textAlign: TextAlign.left,
            maxLines: 1,
            group: labelAutoSizeGroup,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: BlocBuilder<CurrencyCubit, CurrencyState>(
              builder: (BuildContext context, CurrencyState state) {
                int feeSat = paymentData.feeSat;
                if (paymentData.isRefunded) {
                  final int refundTxAmountSat = paymentData.details.map(
                    bitcoin: (PaymentDetails_Bitcoin details) => details.refundTxAmountSat?.toInt() ?? 0,
                    lightning: (PaymentDetails_Lightning details) => details.refundTxAmountSat?.toInt() ?? 0,
                    orElse: () => 0,
                  );
                  feeSat = paymentData.amountSat - refundTxAmountSat;
                }
                final String feeFormatted = BitcoinCurrency.fromTickerSymbol(
                  state.bitcoinTicker,
                ).format(feeSat);
                return Text(
                  feeFormatted,
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
