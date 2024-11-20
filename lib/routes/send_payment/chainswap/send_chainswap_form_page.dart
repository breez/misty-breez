import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('SendChainSwapFormPage');

class SendChainSwapFormPage extends StatefulWidget {
  final BitcoinCurrency bitcoinCurrency;
  final OnchainPaymentLimitsResponse paymentLimits;
  final BitcoinAddressData? btcAddressData;

  const SendChainSwapFormPage({
    required this.bitcoinCurrency,
    required this.paymentLimits,
    super.key,
    this.btcAddressData,
  });

  @override
  State<SendChainSwapFormPage> createState() => _SendChainSwapFormPageState();
}

class _SendChainSwapFormPageState extends State<SendChainSwapFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _withdrawMaxValue = false;

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: <Widget>[
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
            const AvailableBalance(),
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
      _logger.warning('Failed to parse the input amount', e);
    }
    return amount;
  }

  void _prepareSendChainSwap() async {
    final BreezTranslations texts = context.texts();
    final NavigatorState navigator = Navigator.of(context);
    if (_formKey.currentState?.validate() ?? false) {
      final TransparentPageRoute<void> loaderRoute = createLoaderRoute(context);
      navigator.push(loaderRoute);
      try {
        final int amount = _getAmount();
        if (loaderRoute.isActive) {
          navigator.removeRoute(loaderRoute);
        }
        navigator.push(
          FadeInRoute<void>(
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
        _logger.severe('Received error: $error');
        if (!context.mounted) {
          return;
        }
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
