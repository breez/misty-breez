import 'package:flutter/material.dart';
import 'package:misty_breez/widgets/widgets.dart';

class DestinationQRImage extends StatelessWidget {
  final String destination;

  const DestinationQRImage({required this.destination, super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        width: 230.0,
        height: 230.0,
        clipBehavior: Clip.antiAlias,
        decoration: const ShapeDecoration(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
        ),
        child: CompactQRImage(data: destination),
      ),
    );
  }
}
