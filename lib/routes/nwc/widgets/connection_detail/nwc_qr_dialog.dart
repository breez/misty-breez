import 'package:flutter/material.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/widgets/compact_qr_image.dart';

class NwcQrDialog extends StatelessWidget {
  final String connectionString;

  const NwcQrDialog({required this.connectionString, super.key});

  static void show(BuildContext context, String connectionString) {
    showDialog(
      context: context,
      builder: (BuildContext context) => NwcQrDialog(connectionString: connectionString),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double qrSize = screenSize.width * 0.8;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          width: screenSize.width,
          height: screenSize.height,
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Theme.of(context).customData.surfaceBgColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: CompactQRImage(data: connectionString, size: qrSize),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
