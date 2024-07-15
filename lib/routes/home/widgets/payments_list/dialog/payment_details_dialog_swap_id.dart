import 'package:flutter/widgets.dart';
import 'package:l_breez/models/payment_minutiae.dart';
import 'package:l_breez/routes/home/widgets/payments_list/dialog/shareable_payment_row.dart';

class PaymentDetailsSwapId extends StatelessWidget {
  final PaymentMinutiae paymentMinutiae;

  const PaymentDetailsSwapId({required this.paymentMinutiae, super.key});

  @override
  Widget build(BuildContext context) {
    final swapId = paymentMinutiae.swapId;
    return swapId.isNotEmpty
        ? ShareablePaymentRow(
            // TODO: Move this message to Breez-Translations
            title: "Swap ID",
            sharedValue: swapId,
          )
        : const SizedBox.shrink();
  }
}
