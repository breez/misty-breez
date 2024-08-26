import 'package:flutter/widgets.dart';
import 'package:l_breez/cubit/payments/models/payment/payment_data.dart';
import 'package:l_breez/models/payment_details_extension.dart';
import 'package:l_breez/widgets/shareable_payment_row.dart';

class PaymentDetailsSwapId extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentDetailsSwapId({required this.paymentData, super.key});

  @override
  Widget build(BuildContext context) {
    final swapId = paymentData.details?.maybeMap(
          bitcoin: (details) => details.swapId,
          lightning: (details) => details.swapId,
          orElse: () => "",
        ) ??
        "";

    if (swapId.isEmpty) return const SizedBox.shrink();

    return ShareablePaymentRow(
      // TODO: Move this message to Breez-Translations
      title: "Swap ID",
      sharedValue: swapId,
    );
  }
}
