import 'package:flutter/material.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/home/widgets/widgets.dart';

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
        ],
      ),
    );
  }
}