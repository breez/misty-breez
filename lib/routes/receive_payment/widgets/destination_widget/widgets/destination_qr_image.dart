import 'package:flutter/material.dart';
import 'package:l_breez/routes/routes.dart';

class DestinationQRImage extends StatelessWidget {
  final String destination;

  const DestinationQRImage({required this.destination, super.key});

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
