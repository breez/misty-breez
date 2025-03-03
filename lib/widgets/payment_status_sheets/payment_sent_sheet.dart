import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/constants/app_constants.dart';
import 'package:l_breez/widgets/widgets.dart';

Future<dynamic> showPaymentSentSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => const PaymentSentSheet(),
  );
}

class PaymentSentSheet extends StatefulWidget {
  const PaymentSentSheet({super.key});

  @override
  PaymentSentSheetState createState() => PaymentSentSheetState();
}

class PaymentSentSheetState extends State<PaymentSentSheet> {
  @override
  void initState() {
    super.initState();
    // Close the bottom sheet after 2.25 seconds
    Future<void>.delayed(PaymentSheetTiming.popDelay, () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final Size mediaQuerySize = MediaQuery.of(context).size;

    return Container(
      height: mediaQuerySize.height,
      width: mediaQuerySize.width,
      color: themeData.customData.paymentListBgColorLight,
      child: const PaymentSentContent(),
    );
  }
}
