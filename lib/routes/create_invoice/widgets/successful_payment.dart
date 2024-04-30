import 'package:l_breez/routes/create_invoice/widgets/particles_animations.dart';
import 'package:l_breez/routes/create_invoice/widgets/successful_payment_dialog.dart';
import 'package:flutter/material.dart';

class SuccessfulPaymentRoute extends StatefulWidget {
  final Function()? onPrint;

  const SuccessfulPaymentRoute({
    super.key,
    this.onPrint,
  });

  @override
  State<StatefulWidget> createState() {
    return SuccessfulPaymentRouteState();
  }
}

class SuccessfulPaymentRouteState extends State<SuccessfulPaymentRoute> with WidgetsBindingObserver {
  Future? _showFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_showFuture == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _showFuture = showDialog(
          useRootNavigator: false,
          context: context,
          barrierDismissible: true,
          builder: (context) => SuccessfulPaymentDialog(
            onPrint: widget.onPrint,
          ),
        ).whenComplete(() => Navigator.of(context).pop());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Particles(
            50,
            color: Colors.blue.withAlpha(150),
          ),
        ),
      ],
    );
  }
}
