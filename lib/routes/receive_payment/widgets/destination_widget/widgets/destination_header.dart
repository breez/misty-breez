import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/theme/src/theme_extensions.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:service_injector/service_injector.dart';
import 'package:share_plus/share_plus.dart';

class DestinationHeader extends StatelessWidget {
  final AsyncSnapshot<ReceivePaymentResponse>? snapshot;
  final String? destination;
  final String? paymentMethod;

  const DestinationHeader({
    required this.snapshot,
    required this.destination,
    super.key,
    this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final String? destination = this.destination ?? snapshot?.data?.destination;
    return SizedBox(
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          if (paymentMethod != null && paymentMethod!.isNotEmpty) ...<Widget>[
            Text(
              paymentMethod!,
              style: FieldTextStyle.textStyle.copyWith(
                fontSize: 18.0,
              ),
            ),
          ],
          if (destination != null) ...<Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _ShareIcon(
                  destination: destination,
                  paymentMethod: paymentMethod,
                ),
                _CopyIcon(
                  destination: destination,
                  paymentMethod: paymentMethod,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ShareIcon extends StatelessWidget {
  final String destination;
  final String? paymentMethod;

  const _ShareIcon({
    required this.destination,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Tooltip(
      // TODO(erdemyerebasmaz): Add these messages to Breez-Translations
      message: (paymentMethod != null && paymentMethod!.isNotEmpty)
          ? 'Share $paymentMethod'
          : 'Share deposit address',
      child: IconButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 2.0, left: 20.0),
        icon: const Icon(IconData(0xe917, fontFamily: 'icomoon')),
        color: themeData.colorScheme.primary,
        onPressed: () {
          Share.share(destination);
        },
      ),
    );
  }
}

class _CopyIcon extends StatelessWidget {
  final String destination;
  final String? paymentMethod;

  const _CopyIcon({
    required this.destination,
    this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Tooltip(
      message: texts.qr_code_dialog_copy,
      child: IconButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 8.0, left: 2.0),
        icon: const Icon(IconData(0xe90b, fontFamily: 'icomoon')),
        color: themeData.colorScheme.primary,
        onPressed: () {
          ServiceInjector().deviceClient.setClipboardText(destination);
          // TODO(erdemyerebasmaz): Create payment method specific copy messages to Breez-Translations
          showFlushbar(
            context,
            message: (paymentMethod != null && paymentMethod!.isNotEmpty)
                ? texts.payment_details_dialog_copied(paymentMethod!)
                : texts.invoice_btc_address_deposit_address_copied,
            duration: const Duration(seconds: 3),
          );
        },
      ),
    );
  }
}
