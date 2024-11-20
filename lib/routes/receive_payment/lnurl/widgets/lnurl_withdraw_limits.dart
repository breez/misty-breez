import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/src/theme.dart';

class LnUrlWithdrawLimits extends StatelessWidget {
  final LightningPaymentLimitsResponse? limitsResponse;
  final int minWithdrawableSat;
  final int maxWithdrawableSat;
  final Future<void> Function(int amount) onTap;

  const LnUrlWithdrawLimits({
    required this.limitsResponse,
    required this.minWithdrawableSat,
    required this.maxWithdrawableSat,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;

    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    if (limitsResponse == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: AutoSizeText(
          texts.payment_limits_fetch_error_message,
          maxLines: 3,
          textAlign: TextAlign.left,
          style: FieldTextStyle.labelStyle.copyWith(
            color: themeData.isLightTheme ? Colors.red : themeData.colorScheme.error,
          ),
        ),
      );
    }

    final int minNetworkLimit = limitsResponse!.receive.minSat.toInt();
    final int maxNetworkLimit = limitsResponse!.receive.maxSat.toInt();
    final int effectiveMinSat = min(
      max(minNetworkLimit, minWithdrawableSat),
      maxNetworkLimit,
    );
    final int effectiveMaxSat = max(
      minNetworkLimit,
      min(maxNetworkLimit, maxWithdrawableSat),
    );

    // Displays the original range if range is outside payment limits
    final String effMinSendableFormatted = currencyState.bitcoinCurrency.format(
      (effectiveMinSat == effectiveMaxSat) ? minWithdrawableSat : effectiveMinSat,
    );
    final String effMaxSendableFormatted = currencyState.bitcoinCurrency.format(
      (effectiveMinSat == effectiveMaxSat) ? maxWithdrawableSat : effectiveMaxSat,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        RichText(
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
              ),
            ],
          ),
        ),
      ],
    );
  }
}
