import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/receive_payment/widgets/address_widget/address_widget.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:service_injector/service_injector.dart';
import 'package:share_plus/share_plus.dart';

class AddressHeaderWidget extends StatelessWidget {
  final AsyncSnapshot<ReceivePaymentResponse>? snapshot;
  final String? address;
  final String? title;
  final AddressWidgetType type;

  const AddressHeaderWidget({
    super.key,
    this.title,
    required this.address,
    this.type = AddressWidgetType.lightning,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title ?? ""),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (address != null || (snapshot != null && snapshot!.hasData)) ...[
                _ShareIcon(
                  address: address ?? snapshot!.data!.destination,
                  title: title,
                  type: type,
                ),
                _CopyIcon(
                  address: address ?? snapshot!.data!.destination,
                  type: type,
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareIcon extends StatelessWidget {
  final String address;
  final String? title;
  final AddressWidgetType type;

  const _ShareIcon({
    required this.address,
    required this.title,
    this.type = AddressWidgetType.lightning,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Tooltip(
      // TODO: Add these messages to Breez-Translations
      message: (title != null && title!.isNotEmpty) ? "Share $title" : "Share deposit address",
      child: IconButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 2.0, left: 20.0),
        icon: const Icon(IconData(0xe917, fontFamily: 'icomoon')),
        color: themeData.colorScheme.primary,
        onPressed: () {
          Share.share(address);
        },
      ),
    );
  }
}

class _CopyIcon extends StatelessWidget {
  final String address;
  final AddressWidgetType type;

  const _CopyIcon({
    required this.address,
    this.type = AddressWidgetType.lightning,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    return Tooltip(
      message: texts.qr_code_dialog_copy,
      child: IconButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 8.0, left: 2.0),
        icon: const Icon(IconData(0xe90b, fontFamily: 'icomoon')),
        color: themeData.colorScheme.primary,
        onPressed: () {
          ServiceInjector().deviceClient.setClipboardText(address);
          // TODO: Create payment method specific copy messages to Breez-Translations
          showFlushbar(
            context,
            message: type == AddressWidgetType.lightning
                ? texts.qr_code_dialog_copied
                : texts.invoice_btc_address_deposit_address_copied,
            duration: const Duration(seconds: 3),
          );
        },
      ),
    );
  }
}
