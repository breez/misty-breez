import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/src/theme.dart';

class LnUrlPaymentLimits extends StatelessWidget {
  final int effectiveMinSat;
  final int effectiveMaxSat;
  final Future<void> Function(dynamic amount) onTap;

  const LnUrlPaymentLimits({
    super.key,
    required this.effectiveMinSat,
    required this.effectiveMaxSat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;

    final texts = context.texts();

    final effMinSendableFormatted = currencyState.bitcoinCurrency.format(effectiveMinSat);
    final effMaxSendableFormatted = currencyState.bitcoinCurrency.format(effectiveMaxSat);

    return RichText(
      text: TextSpan(
        style: FieldTextStyle.labelStyle,
        children: <TextSpan>[
          TextSpan(
            text: texts.lnurl_fetch_invoice_min(effMinSendableFormatted),
            recognizer: TapGestureRecognizer()..onTap = () => onTap(effectiveMinSat),
          ),
          TextSpan(
            text: texts.lnurl_fetch_invoice_and(effMaxSendableFormatted),
            recognizer: TapGestureRecognizer()..onTap = () => onTap(effectiveMaxSat),
          )
        ],
      ),
    );
  }
}
