import 'package:flutter/material.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/theme/theme.dart';

class PaymentDetailsDialogTitle extends StatelessWidget {
  final PaymentData paymentData;

  const PaymentDetailsDialogTitle({required this.paymentData, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    return Stack(
      children: <Widget>[
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
              paymentData,
              radius: 32.0,
            ),
          ),
        ),
      ],
    );
  }
}
