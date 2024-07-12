import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/routes/chainswap/send/send_chainswap_confirmation_page.dart';
import 'package:l_breez/routes/chainswap/send/send_chainswap_form.dart';
import 'package:l_breez/routes/chainswap/send/widgets/chainswap_available_btc.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/route.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';
import 'package:logging/logging.dart';

final _log = Logger("SendChainSwapFormPage");

class SendChainSwapFormPage extends StatefulWidget {
  final BitcoinAddressData? btcAddressData;
  final BitcoinCurrency bitcoinCurrency;
  final OnchainPaymentLimitsResponse paymentLimits;

  const SendChainSwapFormPage({
    super.key,
    this.btcAddressData,
    required this.bitcoinCurrency,
    required this.paymentLimits,
  });

  @override
  State<SendChainSwapFormPage> createState() => _SendChainSwapFormPageState();
}

class _SendChainSwapFormPageState extends State<SendChainSwapFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _addressController = TextEditingController();
  bool _withdrawMaxValue = false;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            SendChainSwapForm(
              formKey: _formKey,
              amountController: _amountController,
              addressController: _addressController,
              withdrawMaxValue: _withdrawMaxValue,
              btcAddressData: widget.btcAddressData,
              bitcoinCurrency: widget.bitcoinCurrency,
              paymentLimits: widget.paymentLimits,
              onChanged: (bool value) {
                setState(() {
                  _withdrawMaxValue = value;
                });
              },
            ),
            const WithdrawFundsAvailableBtc(),
            Expanded(child: Container()),
            SingleButtonBottomBar(
              text: texts.withdraw_funds_action_next,
              onPressed: _prepareSendChainSwap,
            ),
          ],
        ),
      ),
    );
  }

  int _getAmount() {
    int amount = 0;
    try {
      amount = widget.bitcoinCurrency.parse(_amountController.text);
    } catch (e) {
      _log.warning("Failed to parse the input amount", e);
    }
    return amount;
  }

  void _prepareSendChainSwap() async {
    final texts = context.texts();
    final navigator = Navigator.of(context);
    if (_formKey.currentState?.validate() ?? false) {
      var loaderRoute = createLoaderRoute(context);
      navigator.push(loaderRoute);
      try {
        int amount = _getAmount();
        if (loaderRoute.isActive) {
          navigator.removeRoute(loaderRoute);
        }
        navigator.push(
          FadeInRoute(
            builder: (_) => SendChainSwapConfirmationPage(
              amountSat: amount,
              onchainRecipientAddress: _addressController.text,
              isMaxValue: _withdrawMaxValue,
            ),
          ),
        );
      } catch (error) {
        if (loaderRoute.isActive) {
          navigator.removeRoute(loaderRoute);
        }
        _log.severe("Received error: $error");
        if (!context.mounted) return;
        showFlushbar(
          context,
          message: texts.reverse_swap_upstream_generic_error_message(
            extractExceptionMessage(error, texts),
          ),
        );
      } finally {
        if (loaderRoute.isActive) {
          navigator.removeRoute(loaderRoute);
        }
      }
    }
  }
}
