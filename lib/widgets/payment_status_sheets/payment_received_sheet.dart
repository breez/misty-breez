import 'package:flutter/material.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/widgets/widgets.dart';

Future<dynamic> showPaymentReceivedSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => const PaymentReceivedSheet(),
  );
}

class PaymentReceivedSheet extends StatefulWidget {
  const PaymentReceivedSheet({super.key});

  @override
  PaymentReceivedSheetState createState() => PaymentReceivedSheetState();
}

class PaymentReceivedSheetState extends State<PaymentReceivedSheet> {
  @override
  void initState() {
    super.initState();
    // Close the bottom sheet after 2.25 seconds
    Future<void>.delayed(const Duration(milliseconds: 2250), () {
      if (mounted) {
        Navigator.of(context).popUntil(
          (Route<dynamic> route) => route.settings.name == Home.routeName,
        );
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
      color: themeData.colorScheme.surface,
      child: const PaymentReceivedContent(),
    );
  }
}
