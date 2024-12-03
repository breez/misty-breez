import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';

class LnPaymentFee extends StatelessWidget {
  final bool isCalculatingFees;
  final int? feesSat;

  const LnPaymentFee({
    required this.isCalculatingFees,
    required this.feesSat,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;

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
                        texts.ln_payment_fee_amount_positive(
                          currencyState.bitcoinCurrency.format(feesSat!),
                        ),
                        style: TextStyle(
                          fontSize: 18.0,
                          color: themeData.colorScheme.error.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                      )
                    : AutoSizeText(
                        texts.ln_payment_fee_amount_unknown(currencyState.bitcoinCurrency.displayName),
                        style: TextStyle(
                          fontSize: 18.0,
                          color: themeData.colorScheme.error.withOpacity(0.8),
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
