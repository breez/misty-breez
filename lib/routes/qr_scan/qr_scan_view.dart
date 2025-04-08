import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

final Logger _logger = Logger('QRScan');

class QRScanView extends StatefulWidget {
  static const String routeName = '/qr_scan';

  const QRScanView({super.key});

  @override
  State<StatefulWidget> createState() => QRScanViewState();
}

class QRScanViewState extends State<QRScanView> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool popped = false;
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  late StreamSubscription<BarcodeCapture> _barcodeSubscription;

  @override
  void initState() {
    super.initState();
    _barcodeSubscription = cameraController.barcodes.listen(onDetect);
  }

  void onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final Barcode barcode in barcodes) {
      _logger.info('Barcode detected. ${barcode.displayValue}');
      if (popped || !mounted) {
        _logger.info('Skipping, already popped or not mounted');
        return;
      }
      final String? code = barcode.rawValue;
      if (code == null) {
        _logger.warning('Failed to scan QR code.');
      } else {
        popped = true;
        _logger.info('Popping read QR code: $code');
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
        children: <Widget>[
          Positioned.fill(
            child: Column(
              children: <Widget>[
                Expanded(
                  flex: 5,
                  child: MobileScanner(
                    key: qrKey,
                    controller: cameraController,
                  ),
                ),
              ],
            ),
          ),
          const ScanOverlay(),
          SafeArea(
            child: Stack(
              children: <Widget>[
                Positioned(
                  right: 10,
                  top: 5,
                  child: ImagePickerButton(cameraController: cameraController),
                ),
                if (defaultTargetPlatform == TargetPlatform.iOS) ...<Widget>[
                  const Positioned(
                    bottom: 30.0,
                    right: 0,
                    left: 0,
                    child: QRScanCancelButton(),
                  ),
                ],
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
    final BreezTranslations texts = context.texts();
    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(context);

    return IconButton(
      padding: const EdgeInsets.fromLTRB(0, 32, 24, 0),
      icon: SvgPicture.asset(
        'assets/icons/image.svg',
        colorFilter: const ColorFilter.mode(
          Colors.white,
          BlendMode.srcATop,
        ),
        width: 32,
        height: 32,
      ),
      onPressed: () async {
        final ImagePicker picker = ImagePicker();

        final XFile? image = await picker.pickImage(source: ImageSource.gallery).catchError(
          (Object err) {
            _logger.warning('Failed to pick image', err);
            return null;
          },
        );

        if (image == null) {
          return;
        }

        final String filePath = image.path;
        _logger.info('Picked image: $filePath');

        final BarcodeCapture? barcodes = await cameraController.analyzeImage(filePath).catchError(
          (Object err) {
            _logger.warning('Failed to analyze image', err);
            return null;
          },
        );

        if (barcodes == null) {
          _logger.info('No QR code found in image');
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(texts.qr_scan_gallery_failed)),
          );
        }
      },
    );
  }
}

class QRScanCancelButton extends StatelessWidget {
  const QRScanCancelButton({super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(12.0)),
          border: Border.all(color: Colors.white.withValues(alpha: .8)),
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
