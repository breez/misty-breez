import 'package:breez_translations/breez_translations_locales.dart';
import 'package:l_breez/routes/create_invoice/widgets/compact_qr_image.dart';
import 'package:l_breez/services/injector.dart';
import 'package:l_breez/widgets/address_widget.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:flutter/material.dart';

class AddressQRWidget extends StatelessWidget {
  final String address;
  final String? footer;
  final void Function()? onLongPress;
  final AddressWidgetType type;

  const AddressQRWidget({
    super.key,
    required this.address,
    this.footer,
    this.onLongPress,
    this.type = AddressWidgetType.bitcoin,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    return Column(
      children: [
        GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.only(top: 32.0, bottom: 16.0),
            padding: const EdgeInsets.all(8.6),
            child: CompactQRImage(
              data: type == AddressWidgetType.bitcoin ? "bitcoin:$address" : address,
              size: 180.0,
            ),
          ),
        ),
        if (footer != null)
          Container(
            padding: const EdgeInsets.only(top: 16.0, left: 24, right: 24),
            child: GestureDetector(
              onTap: () {
                ServiceInjector().device.setClipboardText(address);
                showFlushbar(
                  context,
                  message: texts.invoice_btc_address_deposit_address_copied,
                );
              },
              child: Text(
                footer!,
                style: themeData.primaryTextTheme.titleSmall,
              ),
            ),
          ),
      ],
    );
  }
}
