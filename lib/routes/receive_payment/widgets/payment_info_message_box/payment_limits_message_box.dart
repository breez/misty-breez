import 'package:breez_liquid/breez_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/receive_payment/widgets/payment_info_message_box/payment_info_message_box.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/scrollable_error_message_widget.dart';

class PaymentLimitsMessageBox extends StatelessWidget {
  const PaymentLimitsMessageBox({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
      builder: (BuildContext context, PaymentLimitsState snapshot) {
        if (snapshot.hasError) {
          return ScrollableErrorMessageWidget(
            title: "Failed to retrieve payment limits:",
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 0),
            message: texts.reverse_swap_upstream_generic_error_message(snapshot.errorMessage),
          );
        }
        if (snapshot.lightningPaymentLimits == null) {
          final themeData = Theme.of(context);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Loader(
                color: themeData.primaryColor.withOpacity(0.5),
              ),
            ),
          );
        }

        final receivePaymentLimits = snapshot.lightningPaymentLimits!.receive;
        final limitsMessage = _formatLimitsMessage(context, receivePaymentLimits);

        return PaymentInfoMessageBox(message: limitsMessage);
      },
    );
  }

  String _formatLimitsMessage(BuildContext context, Limits limits) {
    final texts = context.texts();
    final currencyState = context.read<CurrencyCubit>().state;

    // Get the minimum sendable amount (in sats), can not be less than 1 or more than maxSendable
    final minSendableSat = limits.minSat.toInt();
    final minSendableAboveMin = minSendableSat >= 1;
    if (!minSendableAboveMin) {
      return "Minimum sendable amount can't be less than ${currencyState.bitcoinCurrency.format(1)}.";
    }

    final maxSendableSat = limits.maxSat.toInt();
    if (minSendableSat > maxSendableSat) {
      return "Minimum sendable amount can't be greater than maximum sendable amount.";
    }
    final minSendableFormatted = currencyState.bitcoinCurrency.format(minSendableSat);
    final maxSendableFormatted = currencyState.bitcoinCurrency.format(maxSendableSat);
    // Send more than {minSendableSat} and up to {maxSendableSat} to this address.
    return texts.invoice_ln_address_channel_not_needed(
      minSendableFormatted,
      maxSendableFormatted,
    );
  }
}
