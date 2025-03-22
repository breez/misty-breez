import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('QrActionButton');

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
          'assets/icons/qr_scan.svg',
          colorFilter: ColorFilter.mode(
            BreezColors.white[500]!,
            BlendMode.srcATop,
          ),
          width: 24.0,
          height: 24.0,
        ),
      ),
    );
  }

  void _scanBarcode(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final InputCubit inputCubit = context.read<InputCubit>();

    _logger.info('Start qr code scan');
    Navigator.pushNamed<String>(context, QRScanView.routeName).then(
      (String? barcode) {
        _logger.info("Scanned string: '$barcode'");
        if (barcode == null) {
          return;
        }
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
