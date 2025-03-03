import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/utils/utils.dart';
import 'package:l_breez/widgets/widgets.dart';

class DestinationQRWidget extends StatelessWidget {
  final AsyncSnapshot<ReceivePaymentResponse>? snapshot;
  final String? destination;
  final String? lnAddress;
  final String? paymentMethod;
  final void Function()? onLongPress;
  final Widget? infoWidget;

  const DestinationQRWidget({
    required this.snapshot,
    required this.destination,
    this.lnAddress,
    this.paymentMethod,
    this.onLongPress,
    this.infoWidget,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final String? destination = this.destination ?? snapshot?.data?.destination;

    if (snapshot?.hasError ?? false) {
      return ScrollableErrorMessageWidget(
        showIcon: true,
        title: '${texts.qr_code_dialog_warning_message_error}:',
        message: ExceptionHandler.extractMessage(snapshot!.error!, texts),
        padding: EdgeInsets.zero,
      );
    } else if (destination == null) {
      return const SizedBox.shrink();
    }
    return Column(
      children: <Widget>[
        GestureDetector(
          onLongPress: onLongPress,
          child: DestinationQRImage(
            destination: destination,
          ),
        ),
        DestinationActions(
          snapshot: snapshot,
          destination: destination,
          paymentMethod: paymentMethod,
          lnAddress: lnAddress,
        ),
        if (lnAddress != null && lnAddress!.isNotEmpty) ...<Widget>[
          DestinationInformation(lnAddress: lnAddress!),
        ],
        if (infoWidget != null) ...<Widget>[
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: infoWidget,
          ),
        ],
      ],
    );
  }
}
