import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:l_breez/bloc/input/input_bloc.dart';
import 'package:l_breez/bloc/input/input_source.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;
import 'package:l_breez/widgets/flushbar.dart';
import 'package:logging/logging.dart';

final _log = Logger("QrActionButton");

class QrActionButton extends StatelessWidget {
  final GlobalKey firstPaymentItemKey;

  const QrActionButton(
    this.firstPaymentItemKey, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: FloatingActionButton(
        onPressed: () => _scanBarcode(context),
        child: SvgPicture.asset(
          "src/icon/qr_scan.svg",
          colorFilter: ColorFilter.mode(
            theme.BreezColors.white[500]!,
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
    InputBloc inputBloc = context.read<InputBloc>();

    _log.info("Start qr code scan");
    Navigator.pushNamed<String>(context, "/qr_scan").then(
      (barcode) {
        _log.info("Scanned string: '$barcode'");
        if (barcode == null) return;
        if (barcode.isEmpty) {
          showFlushbar(
            context,
            message: texts.qr_action_button_error_code_not_detected,
          );
          return;
        }
        inputBloc.addIncomingInput(barcode, InputSource.qrcode_reader);
      },
    );
  }
}
