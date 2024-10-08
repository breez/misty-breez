import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:l_breez/routes/qr_scan/scan_overlay.dart';
import 'package:logging/logging.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

final _log = Logger("QRScan");

class QRScan extends StatefulWidget {
  static const routeName = "/qr_scan";

  const QRScan({super.key});

  @override
  State<StatefulWidget> createState() => QRScanState();
}

class QRScanState extends State<QRScan> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool popped = false;
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  late StreamSubscription<BarcodeCapture> _barcodeSubscription;

  @override
  void initState() {
    super.initState();
    _barcodeSubscription = cameraController.barcodes.listen(onDetect);
  }

  void onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      _log.info("Barcode detected. ${barcode.displayValue}");
      if (popped || !mounted) {
        _log.info("Skipping, already popped or not mounted");
        return;
      }
      final code = barcode.rawValue;
      if (code == null) {
        _log.warning("Failed to scan QR code.");
      } else {
        popped = true;
        _log.info("Popping read QR code: $code");
        Navigator.of(context).pop(code);
      }
    }
  }

  @override
  void dispose() {
    _barcodeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: MobileScanner(
                    key: qrKey,
                    controller: cameraController,
                  ),
                )
              ],
            ),
          ),
          const ScanOverlay(),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  right: 10,
                  top: 5,
                  child: ImagePickerButton(cameraController: cameraController),
                ),
                if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                  const Positioned(
                    bottom: 30.0,
                    right: 0,
                    left: 0,
                    child: QRScanCancelButton(),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ImagePickerButton extends StatelessWidget {
  final MobileScannerController cameraController;

  const ImagePickerButton({required this.cameraController, super.key});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return IconButton(
      padding: const EdgeInsets.fromLTRB(0, 32, 24, 0),
      icon: SvgPicture.asset(
        "assets/icons/image.svg",
        colorFilter: const ColorFilter.mode(
          Colors.white,
          BlendMode.srcATop,
        ),
        width: 32,
        height: 32,
      ),
      onPressed: () async {
        final ImagePicker picker = ImagePicker();

        final XFile? image = await picker.pickImage(source: ImageSource.gallery).catchError((err) {
          _log.warning("Failed to pick image", err);
          return null;
        });

        if (image == null) return;

        var filePath = image.path;
        _log.info("Picked image: $filePath");

        final BarcodeCapture? barcodes = await cameraController.analyzeImage(filePath).catchError(
          (err) {
            _log.warning("Failed to analyze image", err);
            return null;
          },
        );

        if (barcodes == null) {
          _log.info("No QR code found in image");
          scaffoldMessenger.showSnackBar(SnackBar(content: Text(texts.qr_scan_gallery_failed)));
        }
      },
    );
  }
}

class QRScanCancelButton extends StatelessWidget {
  const QRScanCancelButton({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(12.0)),
          border: Border.all(color: Colors.white.withOpacity(0.8)),
        ),
        child: TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 35),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            texts.qr_scan_action_cancel,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
