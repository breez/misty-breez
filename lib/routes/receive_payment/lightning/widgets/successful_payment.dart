import 'package:flutter/material.dart';
import 'package:l_breez/routes/receive_payment/lightning/widgets/particle_animations/particles_animations.dart';
import 'package:l_breez/routes/receive_payment/lightning/widgets/successful_payment_dialog.dart';

class SuccessfulPaymentRoute extends StatefulWidget {
  final Function()? onPrint;

  const SuccessfulPaymentRoute({super.key, this.onPrint});

  @override
  State<StatefulWidget> createState() => SuccessfulPaymentRouteState();
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
        ).whenComplete(() {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
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
