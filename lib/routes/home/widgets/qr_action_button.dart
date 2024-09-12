import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/qr_scan/qr_scan.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:logging/logging.dart';

final _log = Logger("QrActionButton");

class QrActionButton extends StatelessWidget {
  final GlobalKey firstPaymentItemKey;

  const QrActionButton(this.firstPaymentItemKey, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: FloatingActionButton(
        onPressed: () => _scanBarcode(context),
        child: SvgPicture.asset(
          "assets/icons/qr_scan.svg",
          colorFilter: ColorFilter.mode(
            BreezColors.white[500]!,
            BlendMode.srcATop,
          ),
          fit: BoxFit.contain,
          width: 24.0,
          height: 24.0,
        ),
      ),
    );
  }

  void _scanBarcode(BuildContext context) {
    final texts = context.texts();
    final inputCubit = context.read<InputCubit>();

    _log.info("Start qr code scan");
    Navigator.pushNamed<String>(context, QRScan.routeName).then(
      (barcode) {
        _log.info("Scanned string: '$barcode'");
        if (barcode == null) return;
        if (barcode.isEmpty && context.mounted) {
          showFlushbar(
            context,
            message: texts.qr_action_button_error_code_not_detected,
          );
          return;
        }
        inputCubit.addIncomingInput(barcode, InputSource.qrcodeReader);
      },
    );
  }
}
