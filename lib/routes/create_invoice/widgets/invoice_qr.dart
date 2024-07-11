import 'package:flutter/material.dart';
import 'package:l_breez/routes/create_invoice/widgets/compact_qr_image.dart';

class InvoiceQR extends StatelessWidget {
  final String bolt11;
  final bool bip21;

  const InvoiceQR({
    super.key,
    required this.bolt11,
    this.bip21 = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: SizedBox(
          width: 230.0,
          height: 230.0,
          child: CompactQRImage(data: bolt11, bip21: bip21),
        ),
      ),
    );
  }
}
