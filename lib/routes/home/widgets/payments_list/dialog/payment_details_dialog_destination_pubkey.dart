import 'package:flutter/widgets.dart';
import 'package:l_breez/models/payment_minutiae.dart';
import 'package:l_breez/routes/home/widgets/payments_list/dialog/shareable_payment_row.dart';

class PaymentDetailsDestinationPubkey extends StatelessWidget {
  final PaymentMinutiae paymentMinutiae;

  const PaymentDetailsDestinationPubkey({required this.paymentMinutiae, super.key});

  @override
  Widget build(BuildContext context) {
    final destinationPubkey = paymentMinutiae.swapId;
    return destinationPubkey.isNotEmpty
        ? ShareablePaymentRow(
            // TODO: Move this message to Breez-Translations
            title: "Swap ID",
            sharedValue: destinationPubkey,
          )
        : const SizedBox.shrink();
  }
}
