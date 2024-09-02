import 'package:breez_translations/breez_translations_locales.dart';
import 'package:l_breez/widgets/address_widget.dart';
import 'package:flutter/material.dart';

class LnAddressWidget extends StatefulWidget {
  final String lnurlPayUrl;

  const LnAddressWidget(this.lnurlPayUrl, {super.key});

  @override
  State<LnAddressWidget> createState() => _LnAddressWidgetState();
}

class _LnAddressWidgetState extends State<LnAddressWidget> {
  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        AddressWidget(
          widget.lnurlPayUrl,
          title: texts.invoice_ln_address_address_information,
          type: AddressWidgetType.lnurl,
        ),
      ],
    );
  }
}
