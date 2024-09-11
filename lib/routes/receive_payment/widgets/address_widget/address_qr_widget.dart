import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/receive_payment/lightning/widgets/widgets.dart';
import 'package:l_breez/routes/receive_payment/widgets/address_widget/address_qr.dart';
import 'package:l_breez/routes/receive_payment/widgets/address_widget/address_widget.dart';
import 'package:l_breez/utils/exceptions.dart';

class AddressQRWidget extends StatelessWidget {
  final String? address;
  final String? footer;
  final AsyncSnapshot<ReceivePaymentResponse>? snapshot;
  final void Function()? onLongPress;
  final AddressWidgetType type;
  final Widget? feeWidget;

  const AddressQRWidget({
    super.key,
    required this.address,
    this.footer,
    this.onLongPress,
    this.type = AddressWidgetType.lightning,
    this.feeWidget,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return AnimatedCrossFade(
      firstChild: LoadingOrError(
        error: snapshot?.error,
        displayErrorMessage: snapshot?.error != null
            ? extractExceptionMessage(snapshot!.error!, texts)
            : texts.qr_code_dialog_warning_message_error,
      ),
      secondChild: address == null && snapshot?.data == null
          ? const SizedBox.shrink()
          : Column(
              children: [
                AddressQR(bolt11: address ?? snapshot!.data!.destination, bip21: true),
                if (feeWidget != null) ...[
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: feeWidget,
                  ),
                ]
              ],
            ),
      duration: const Duration(seconds: 1),
      crossFadeState:
          address == null && snapshot?.data == null ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }
}
