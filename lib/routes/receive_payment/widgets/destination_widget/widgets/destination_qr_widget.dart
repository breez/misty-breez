import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/routes.dart';

class DestinationQRWidget extends StatelessWidget {
  final AsyncSnapshot<ReceivePaymentResponse>? snapshot;
  final String? destination;
  final void Function()? onLongPress;
  final Widget? infoWidget;

  const DestinationQRWidget({
    required this.snapshot,
    required this.destination,
    super.key,
    this.onLongPress,
    this.infoWidget,
  });

  @override
  Widget build(BuildContext context) {
    final String? destination = this.destination ?? snapshot?.data?.destination;

    return AnimatedCrossFade(
      firstChild: LoadingOrError(error: snapshot?.error),
      secondChild: destination == null
          ? const SizedBox.shrink()
          : Column(
              children: <Widget>[
                GestureDetector(
                  onLongPress: onLongPress,
                  child: DestinationQRImage(
                    destination: destination,
                  ),
                ),
                if (infoWidget != null) ...<Widget>[
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: infoWidget,
                  ),
                ],
              ],
            ),
      duration: const Duration(seconds: 1),
      crossFadeState: destination == null ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }
}
