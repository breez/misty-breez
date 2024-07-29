import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/cubit/payments/models/models.dart';
import 'package:l_breez/widgets/shareable_payment_row.dart';

class PaymentDetailsPreimage extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentDetailsPreimage({super.key, required this.paymentData});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    final paymentPreimage = paymentData.preimage;
    if (paymentPreimage.isNotEmpty) {
      return ShareablePaymentRow(
        title: texts.payment_details_dialog_single_info_pre_image,
        sharedValue: paymentPreimage,
      );
    } else {
      return Container();
    }
  }
}
