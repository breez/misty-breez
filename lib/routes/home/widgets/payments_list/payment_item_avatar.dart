import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/models/payment_minutiae.dart';
import 'package:l_breez/widgets/breez_avatar.dart';

class PaymentItemAvatar extends StatelessWidget {
  final PaymentMinutiae paymentMinutiae;
  final double radius;

  const PaymentItemAvatar(
    this.paymentMinutiae, {
    this.radius = 20.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (true) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        child: Icon(
          paymentMinutiae.paymentType == PaymentType.receive ? Icons.add_rounded : Icons.remove_rounded,
          color: const Color(0xb3303234),
        ),
      );
      // TODO: Liquid - Check if payment's metadata has image - https://github.com/breez/breez-liquid-sdk/issues/232
      // ignore: dead_code
    } else {
      return BreezAvatar("", radius: radius);
    }
  }
}
