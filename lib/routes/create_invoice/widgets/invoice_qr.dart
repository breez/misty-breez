import 'package:l_breez/routes/create_invoice/widgets/compact_qr_image.dart';
import 'package:flutter/material.dart';

class InvoiceQR extends StatelessWidget {
  final String bolt11;

  const InvoiceQR({
    super.key,
    required this.bolt11,
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
          child: CompactQRImage(data: bolt11),
        ),
      ),
    );
  }
}
