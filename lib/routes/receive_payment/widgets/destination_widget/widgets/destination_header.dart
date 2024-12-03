import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/theme/src/theme.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:service_injector/service_injector.dart';
import 'package:share_plus/share_plus.dart';

class DestinationActions extends StatelessWidget {
  final AsyncSnapshot<ReceivePaymentResponse>? snapshot;
  final String? destination;
  final String? paymentMethod;

  const DestinationActions({
    required this.snapshot,
    required this.destination,
    super.key,
    this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final String? destination = this.destination ?? snapshot?.data?.destination;
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: (destination != null)
            ? <Widget>[
                Expanded(
                  child: _CopyButton(
                    destination: destination,
                    paymentMethod: paymentMethod,
                  ),
                ),
                const SizedBox(width: 32.0),
                Expanded(
                  child: _ShareButton(
                    destination: destination,
                    paymentMethod: paymentMethod,
                  ),
                ),
              ]
            : <Widget>[],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  final String destination;
  final String? paymentMethod;

  const _CopyButton({
    required this.destination,
    this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 48.0,
        minWidth: 138.0,
      ),
      child: Tooltip(
        message: texts.qr_code_dialog_copy,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(
            IconData(0xe90b, fontFamily: 'icomoon'),
            size: 20.0,
          ),
          // TODO(erdemyerebasmaz): Add these messages to Breez-Translations
          label: const Text(
            'COPY',
            style: balanceFiatConversionTextStyle,
          ),
          onPressed: () {
            ServiceInjector().deviceClient.setClipboardText(destination);
            showFlushbar(
              context,
              message: (paymentMethod != null && paymentMethod!.isNotEmpty)
                  ? texts.payment_details_dialog_copied(paymentMethod!)
                  : texts.invoice_btc_address_deposit_address_copied,
              duration: const Duration(seconds: 3),
            );
          },
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final String destination;
  final String? paymentMethod;

  const _ShareButton({
    required this.destination,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 48.0,
        minWidth: 138.0,
      ),
      child: Tooltip(
        // TODO(erdemyerebasmaz): Add these messages to Breez-Translations
        message: (paymentMethod != null && paymentMethod!.isNotEmpty)
            ? 'Share $paymentMethod'
            : 'Share deposit address',
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(
            IconData(0xe917, fontFamily: 'icomoon'),
            size: 20.0,
          ),
          // TODO(erdemyerebasmaz): Add these messages to Breez-Translations
          label: const Text(
            'SHARE',
            style: balanceFiatConversionTextStyle,
          ),
          onPressed: () {
            Share.share(destination);
          },
        ),
      ),
    );
  }
}
