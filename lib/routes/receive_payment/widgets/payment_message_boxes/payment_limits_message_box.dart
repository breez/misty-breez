import 'package:breez_liquid/breez_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/widgets/widgets.dart';

class PaymentLimitsMessageBox extends StatelessWidget {
  const PaymentLimitsMessageBox({super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
      builder: (BuildContext context, PaymentLimitsState snapshot) {
        if (snapshot.hasError) {
          return ScrollableErrorMessageWidget(
            title: texts.payment_limits_generic_error_title,
            padding: const EdgeInsets.symmetric(vertical: 20),
            message: texts.reverse_swap_upstream_generic_error_message(snapshot.errorMessage),
          );
        }
        if (snapshot.lightningPaymentLimits == null) {
          final ThemeData themeData = Theme.of(context);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Loader(
                color: themeData.primaryColor.withOpacity(0.5),
              ),
            ),
          );
        }

        final Limits receivePaymentLimits = snapshot.lightningPaymentLimits!.receive;
        final String limitsMessage = _formatLimitsMessage(context, receivePaymentLimits);

        return PaymentInfoMessageBox(message: limitsMessage);
      },
    );
  }

  String _formatLimitsMessage(BuildContext context, Limits limits) {
    final BreezTranslations texts = context.texts();
    final CurrencyState currencyState = context.read<CurrencyCubit>().state;

    // Get the minimum sendable amount (in sats), can not be less than 1 or more than maxSendable
    final int minSendableSat = limits.minSat.toInt();
    final bool minSendableAboveMin = minSendableSat >= 1;
    if (!minSendableAboveMin) {
      return "Minimum sendable amount can't be less than ${currencyState.bitcoinCurrency.format(1)}.";
    }

    final int maxSendableSat = limits.maxSat.toInt();
    if (minSendableSat > maxSendableSat) {
      return "Minimum sendable amount can't be greater than maximum sendable amount.";
    }
    final String minSendableFormatted = currencyState.bitcoinCurrency.format(minSendableSat);
    final String maxSendableFormatted = currencyState.bitcoinCurrency.format(maxSendableSat);
    // Send more than {minSendableSat} and up to {maxSendableSat} to this address.
    return texts.invoice_ln_address_channel_not_needed(
      minSendableFormatted,
      maxSendableFormatted,
    );
  }
}