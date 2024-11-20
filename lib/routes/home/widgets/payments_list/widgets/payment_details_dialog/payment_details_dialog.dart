import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/home/home.dart';
import 'package:logging/logging.dart';

export 'widgets/widgets.dart';

final AutoSizeGroup _labelGroup = AutoSizeGroup();
final AutoSizeGroup _valueGroup = AutoSizeGroup();

final Logger _logger = Logger('PaymentDetailsDialog');

class PaymentDetailsDialog extends StatelessWidget {
  final PaymentData paymentData;

  PaymentDetailsDialog({required this.paymentData, super.key}) {
    _logger.info('PaymentDetailsDialog for payment: $paymentData');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: PaymentDetailsDialogTitle(paymentData: paymentData),
      contentPadding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PaymentDetailsDialogContentTitle(paymentData: paymentData),
              PaymentDetailsDialogDescription(paymentData: paymentData),
              PaymentDetailsDialogAmount(
                paymentData: paymentData,
                labelAutoSizeGroup: _labelGroup,
                valueAutoSizeGroup: _valueGroup,
              ),
              PaymentDetailsDialogRefundTxAmount(
                paymentData: paymentData,
                labelAutoSizeGroup: _labelGroup,
                valueAutoSizeGroup: _valueGroup,
              ),
              PaymentDetailsDialogDate(
                paymentData: paymentData,
                labelAutoSizeGroup: _labelGroup,
                valueAutoSizeGroup: _valueGroup,
              ),
              PaymentDetailsBolt11(paymentData: paymentData),
              PaymentDetailsPreimage(paymentData: paymentData),
              PaymentDetailsTxId(paymentData: paymentData),
              PaymentDetailsSwapId(paymentData: paymentData),
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
