import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/receive_payment/widgets/destination_widget/destination_qr_image.dart';
import 'package:l_breez/routes/receive_payment/widgets/destination_widget/widgets/widgets.dart';
import 'package:l_breez/utils/exceptions.dart';

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
    final BreezTranslations texts = context.texts();

    final String? destination = this.destination ?? snapshot?.data?.destination;

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
