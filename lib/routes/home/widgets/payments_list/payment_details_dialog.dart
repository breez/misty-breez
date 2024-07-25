import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/models/payment_minutiae.dart';
import 'package:l_breez/routes/home/widgets/payments_list/dialog/payment_details_dialog.dart';
import 'package:logging/logging.dart';

final AutoSizeGroup _labelGroup = AutoSizeGroup();
final AutoSizeGroup _valueGroup = AutoSizeGroup();

final _log = Logger("PaymentDetailsDialog");

class PaymentDetailsDialog extends StatelessWidget {
  final PaymentMinutiae paymentMinutiae;

  PaymentDetailsDialog({super.key, required this.paymentMinutiae}) {
    _log.info("PaymentDetailsDialog for payment: $paymentMinutiae");
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: PaymentDetailsDialogTitle(paymentMinutiae: paymentMinutiae),
      contentPadding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PaymentDetailsDialogContentTitle(paymentMinutiae: paymentMinutiae),
              PaymentDetailsDialogAmount(
                paymentMinutiae: paymentMinutiae,
                labelAutoSizeGroup: _labelGroup,
                valueAutoSizeGroup: _valueGroup,
              ),
              PaymentDetailsDialogRefundTxAmount(
                paymentMinutiae: paymentMinutiae,
                labelAutoSizeGroup: _labelGroup,
                valueAutoSizeGroup: _valueGroup,
              ),
              PaymentDetailsDialogDate(
                paymentMinutiae: paymentMinutiae,
                labelAutoSizeGroup: _labelGroup,
                valueAutoSizeGroup: _valueGroup,
              ),
              PaymentDetailsBolt11(paymentMinutiae: paymentMinutiae),
              PaymentDetailsPreimage(paymentMinutiae: paymentMinutiae),
              PaymentDetailsTxId(paymentMinutiae: paymentMinutiae),
              PaymentDetailsSwapId(paymentMinutiae: paymentMinutiae),
            ],
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(12.0),
          top: Radius.circular(13.0),
        ),
      ),
    );
  }
}
