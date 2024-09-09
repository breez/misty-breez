import 'package:breez_liquid/breez_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/warning_box.dart';

class LnAddressFeeMessage extends StatelessWidget {
  const LnAddressFeeMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    return BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
      builder: (BuildContext context, PaymentLimitsState snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 0),
              child: Text(
                texts.reverse_swap_upstream_generic_error_message(snapshot.errorMessage),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (snapshot.lightningPaymentLimits == null) {
          final themeData = Theme.of(context);

          return Center(
            child: Loader(
              color: themeData.primaryColor.withOpacity(0.5),
            ),
          );
        }

        return WarningBox(
          boxPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
          contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatFeeMessage(context, snapshot.lightningPaymentLimits!.receive),
                style: themeData.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatFeeMessage(BuildContext context, Limits lightningReceiveLimits) {
    final texts = context.texts();
    final currencyState = context.read<CurrencyCubit>().state;

    // Get the minimum sendable amount (in sats), can not be less than 1 or more than maxSendable
    final minSendableSat = lightningReceiveLimits.minSat.toInt();
    final minSendableAboveMin = minSendableSat >= 1;
    if (!minSendableAboveMin) {
      return "Minimum sendable amount can't be less than ${currencyState.bitcoinCurrency.format(1)}.";
    }

    final maxSendableSat = lightningReceiveLimits.maxSat.toInt();
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
