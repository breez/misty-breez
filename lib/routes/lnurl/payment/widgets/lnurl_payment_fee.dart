import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';

class LnUrlPaymentFee extends StatelessWidget {
  final bool isCalculatingFees;
  final int? feesSat;

  const LnUrlPaymentFee({
    super.key,
    required this.isCalculatingFees,
    required this.feesSat,
  });

  @override
  Widget build(BuildContext context) {
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;

    final texts = context.texts();
    final themeData = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AutoSizeText(
            "${texts.csv_exporter_fee}:",
            style: themeData.primaryTextTheme.headlineMedium,
            textAlign: TextAlign.left,
            maxLines: 1,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: (isCalculatingFees)
                ? Center(
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: themeData.primaryColor.withOpacity(0.5),
                      ),
                    ),
                  )
                : (feesSat != null)
                    ? AutoSizeText(
                        texts.payment_details_dialog_amount_positive(
                          currencyState.bitcoinCurrency.format(
                            feesSat!,
                          ),
                        ),
                        style: TextStyle(
                          color: themeData.colorScheme.error.withOpacity(0.4),
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                      )
                    : AutoSizeText(
                        texts.payment_details_dialog_amount_positive(
                          "? ${currencyState.bitcoinCurrency.displayName}",
                        ),
                        style: TextStyle(
                          color: themeData.colorScheme.error.withOpacity(0.4),
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                      ),
          ),
        ),
      ],
    );
  }
}
