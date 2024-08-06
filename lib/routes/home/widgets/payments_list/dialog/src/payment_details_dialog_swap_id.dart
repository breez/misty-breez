import 'package:flutter/widgets.dart';
import 'package:l_breez/cubit/payments/models/models.dart';
import 'package:l_breez/widgets/shareable_payment_row.dart';

class PaymentDetailsSwapId extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentDetailsSwapId({required this.paymentData, super.key});

  @override
  Widget build(BuildContext context) {
    final swapId = paymentData.swapId;
    return swapId.isNotEmpty
        ? ShareablePaymentRow(
            // TODO: Move this message to Breez-Translations
            title: "Swap ID",
            sharedValue: swapId,
          )
        : const SizedBox.shrink();
  }
}
