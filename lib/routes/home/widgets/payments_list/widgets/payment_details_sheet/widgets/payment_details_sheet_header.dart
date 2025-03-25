import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/home/widgets/widgets.dart';
import 'package:misty_breez/theme/theme.dart';

class PaymentDetailsSheetHeader extends StatefulWidget {
  final PaymentData paymentData;

  const PaymentDetailsSheetHeader({
    required this.paymentData,
    super.key,
  });

  @override
  State<PaymentDetailsSheetHeader> createState() => _PaymentDetailsSheetHeaderState();
}

class _PaymentDetailsSheetHeaderState extends State<PaymentDetailsSheetHeader> {
  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return Center(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 128,
                  minWidth: 128,
                  maxHeight: 128,
                  maxWidth: 128,
                ),
                child: PaymentItemAvatar(
                  widget.paymentData,
                  radius: 64.0,
                ),
              ),
            ),
          ),
          PaymentDetailsSheetContentTitle(paymentData: widget.paymentData),
          PaymentDetailsSheetDescription(paymentData: widget.paymentData),
          if (widget.paymentData.status == PaymentState.refundPending) ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Chip(
                label: const Text('Pending Refund'),
                backgroundColor: themeData.customData.pendingTextColor,
              ),
            ),
          ],
          if (widget.paymentData.isRefunded ||
              widget.paymentData.status == PaymentState.refundable) ...<Widget>[
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Chip(
                label: Text('FAILED'),
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
