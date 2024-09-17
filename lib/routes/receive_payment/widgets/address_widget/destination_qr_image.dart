import 'package:flutter/material.dart';
import 'package:l_breez/routes/receive_payment/lightning/widgets/compact_qr_image.dart';

class DestinationQRImage extends StatelessWidget {
  final String destination;

  const DestinationQRImage({super.key, required this.destination});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: SizedBox(
        width: 230.0,
        height: 230.0,
        child: CompactQRImage(
          data: destination,
        ),
      ),
    );
  }
}
