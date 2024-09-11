import 'package:flutter/material.dart';
import 'package:l_breez/routes/receive_payment/lightning/widgets/compact_qr_image.dart';

class AddressQR extends StatelessWidget {
  final String bolt11;
  final bool bip21;

  const AddressQR({super.key, required this.bolt11, this.bip21 = true});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: SizedBox(
        width: 230.0,
        height: 230.0,
        child: CompactQRImage(
          data: bolt11,
          bip21: bip21,
        ),
      ),
    );
  }
}
