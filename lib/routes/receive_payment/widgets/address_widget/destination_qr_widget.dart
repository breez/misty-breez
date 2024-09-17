import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/receive_payment/lightning/widgets/widgets.dart';
import 'package:l_breez/routes/receive_payment/widgets/address_widget/destination_qr_image.dart';
import 'package:l_breez/utils/exceptions.dart';

class DestinationQRWidget extends StatelessWidget {
  final AsyncSnapshot<ReceivePaymentResponse>? snapshot;
  final String? destination;
  final void Function()? onLongPress;
  final Widget? infoWidget;

  const DestinationQRWidget({
    super.key,
    required this.snapshot,
    required this.destination,
    this.onLongPress,
    this.infoWidget,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    final destination = this.destination ?? snapshot?.data?.destination;

    return AnimatedCrossFade(
      firstChild: LoadingOrError(
        error: snapshot?.error,
        displayErrorMessage: snapshot?.error != null
            ? extractExceptionMessage(snapshot!.error!, texts)
            : texts.qr_code_dialog_warning_message_error,
      ),
      secondChild: destination == null
          ? const SizedBox.shrink()
          : Column(
              children: [
                GestureDetector(
                  onLongPress: onLongPress,
                  child: DestinationQRImage(
                    destination: destination,
                  ),
                ),
                if (infoWidget != null) ...[
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: infoWidget,
                  ),
                ]
              ],
            ),
      duration: const Duration(seconds: 1),
      crossFadeState: destination == null ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }
}
