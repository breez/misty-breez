import 'package:flutter/material.dart';
import 'package:l_breez/models/payment_minutiae.dart';
import 'package:l_breez/routes/home/widgets/payments_list/payment_item_avatar.dart';
import 'package:l_breez/theme/theme_extensions.dart';

class PaymentDetailsDialogTitle extends StatelessWidget {
  final PaymentMinutiae paymentMinutiae;

  const PaymentDetailsDialogTitle({
    super.key,
    required this.paymentMinutiae,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Stack(
      children: [
        Container(
          decoration: ShapeDecoration(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(12.0),
              ),
            ),
            color: themeData.isLightTheme ? themeData.primaryColorDark : themeData.canvasColor,
          ),
          height: 64.0,
          width: mediaQuery.size.width,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 32.0),
          child: Center(
            child: PaymentItemAvatar(
              paymentMinutiae,
              radius: 32.0,
            ),
          ),
        ),
      ],
    );
  }
}
