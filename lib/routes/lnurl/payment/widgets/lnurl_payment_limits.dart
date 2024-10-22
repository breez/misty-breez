import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/src/theme.dart';

class LnUrlPaymentLimits extends StatelessWidget {
  final LightningPaymentLimitsResponse? limitsResponse;
  final int minSendableSat;
  final int maxSendableSat;
  final Future<void> Function(dynamic amount) onTap;

  const LnUrlPaymentLimits({
    super.key,
    required this.limitsResponse,
    required this.minSendableSat,
    required this.maxSendableSat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;

    final texts = context.texts();
    final themeData = Theme.of(context);

    if (limitsResponse == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: AutoSizeText(
          "Failed to fetch payment limits.",
          maxLines: 3,
          textAlign: TextAlign.left,
          style: FieldTextStyle.labelStyle.copyWith(
            color: themeData.isLightTheme ? Colors.red : themeData.colorScheme.error,
          ),
        ),
      );
    }
    final effectiveMinSat = min(
      max(limitsResponse!.send.minSat.toInt(), minSendableSat),
      limitsResponse!.send.maxSat.toInt(),
    );
    final effectiveMaxSat = min(limitsResponse!.send.maxSat.toInt(), maxSendableSat);
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
