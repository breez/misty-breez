import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' show Limits;
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/services/services.dart';
import 'package:misty_breez/widgets/widgets.dart';

class AmountlessBtcAddressMessageBox extends StatelessWidget {
  final AmountlessBtcState amountlessBtcState;

  const AmountlessBtcAddressMessageBox(this.amountlessBtcState, {super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
      builder: (BuildContext context, PaymentLimitsState snapshot) {
        if (snapshot.hasError) {
          return ScrollableErrorMessageWidget(
            title: texts.payment_limits_generic_error_title,
            padding: const EdgeInsets.symmetric(vertical: 20),
            message: texts.reverse_swap_upstream_generic_error_message(snapshot.errorMessage),
          );
        }
        if (snapshot.onchainPaymentLimits == null) {
          return const CenteredLoader();
        }

        final String limitsMessage = _formatAmountlessBtcMessage(context, snapshot, amountlessBtcState);
        const String feeInfoUrl =
            'https://sdk-doc-liquid.breez.technology/guide/base_fees.html#receiving-from-a-btc-address';
        return WarningBox(
          boxPadding: EdgeInsets.zero,
          backgroundColor: themeData.colorScheme.error.withValues(alpha: .1),
          contentPadding: const EdgeInsets.all(16.0),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: limitsMessage,
              style: themeData.textTheme.titleLarge?.copyWith(color: themeData.colorScheme.error),
              children: <InlineSpan>[
                TextSpan(
                  text: 'here',
                  style: themeData.textTheme.titleLarge?.copyWith(
                    color: themeData.colorScheme.error,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => ExternalBrowserService.launchLink(context, linkAddress: feeInfoUrl),
                ),
                TextSpan(
                  text: '.',
                  style: themeData.textTheme.titleLarge?.copyWith(color: themeData.colorScheme.error),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatAmountlessBtcMessage(
    BuildContext context,
    PaymentLimitsState snapshot,
    AmountlessBtcState amountlessBtcState,
  ) {
    final BreezTranslations texts = context.texts();
    final CurrencyState currencyState = context.read<CurrencyCubit>().state;

    final Limits limits = snapshot.onchainPaymentLimits!.receive;
    final String minReceivableFormatted = currencyState.bitcoinCurrency.format(limits.minSat.toInt());
    final String maxReceivableFormatted = currencyState.bitcoinCurrency.format(limits.maxSat.toInt());
    // TODO(erdemyerebasmaz): Add fee info message to Breez-Translations.
    final String feeInfoMsg = 'Receiving funds incurs a fee as specified';
    return '${texts.payment_limits_message(minReceivableFormatted, maxReceivableFormatted)} This address can be used only once. $feeInfoMsg ';
  }
}
