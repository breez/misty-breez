import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/theme/src/theme.dart';
import 'package:l_breez/utils/a11y/min_font_size.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:service_injector/service_injector.dart';
import 'package:share_plus/share_plus.dart';

class DestinationActions extends StatelessWidget {
  final AsyncSnapshot<ReceivePaymentResponse>? snapshot;
  final String? destination;
  final String? lnAddress;
  final String? paymentMethod;

  const DestinationActions({
    required this.snapshot,
    required this.destination,
    this.lnAddress,
    this.paymentMethod,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AutoSizeGroup textGroup = AutoSizeGroup();

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
                    lnAddress: lnAddress,
                    paymentMethod: paymentMethod,
                    textGroup: textGroup,
                  ),
                ),
                const SizedBox(width: 32.0),
                Expanded(
                  child: _ShareButton(
                    destination: destination,
                    paymentMethod: paymentMethod,
                    textGroup: textGroup,
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
  final String? lnAddress;
  final AutoSizeGroup? textGroup;

  const _CopyButton({
    required this.destination,
    this.paymentMethod,
    this.lnAddress,
    this.textGroup,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final MinFontSize minFont = MinFontSize(context);

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
          label: AutoSizeText(
            texts.destination_action_copy_label,
            style: balanceFiatConversionTextStyle,
            maxLines: 1,
            group: textGroup,
            minFontSize: minFont.minFontSize,
            stepGranularity: 0.1,
          ),
          onPressed: () {
            ServiceInjector().deviceClient.setClipboardText(
                  (lnAddress != null && lnAddress!.isNotEmpty) ? lnAddress! : destination,
                );
            showFlushbar(
              context,
              message: (lnAddress != null && lnAddress!.isNotEmpty) ||
                      (paymentMethod != null && paymentMethod!.isNotEmpty)
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
  final AutoSizeGroup? textGroup;

  const _ShareButton({
    required this.destination,
    required this.paymentMethod,
    this.textGroup,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final MinFontSize minFont = MinFontSize(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 48.0,
        minWidth: 138.0,
      ),
      child: Tooltip(
        message: (paymentMethod != null && paymentMethod!.isNotEmpty)
            ? texts.destination_action_share_payment_method_tooltip(paymentMethod!)
            : texts.destination_action_share_default_tooltip,
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
          label: AutoSizeText(
            texts.destination_action_share_label,
            style: balanceFiatConversionTextStyle,
            maxLines: 1,
            group: textGroup,
            minFontSize: minFont.minFontSize,
            stepGranularity: 0.1,
          ),
          onPressed: () {
            Share.share(destination);
          },
        ),
      ),
    );
  }
}
