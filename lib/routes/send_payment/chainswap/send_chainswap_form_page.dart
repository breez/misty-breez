import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/routes/routes.dart';

class SendChainSwapFormPage extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final BitcoinCurrency bitcoinCurrency;
  final OnchainPaymentLimitsResponse paymentLimits;
  final BitcoinAddressData? btcAddressData;
  final TextEditingController amountController;
  final TextEditingController addressController;
  final bool isDrain;
  final ValueChanged<bool> onChanged;

  const SendChainSwapFormPage({
    required this.formKey,
    required this.bitcoinCurrency,
    required this.paymentLimits,
    required this.amountController,
    required this.addressController,
    required this.isDrain,
    required this.onChanged,
    super.key,
    this.btcAddressData,
  });

  @override
  State<SendChainSwapFormPage> createState() => _SendChainSwapFormPageState();
}

class _SendChainSwapFormPageState extends State<SendChainSwapFormPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
        child: Column(
          children: <Widget>[
            Container(
              decoration: const ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(12),
                  ),
                ),
                color: Color.fromRGBO(40, 59, 74, 0.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: SendChainSwapForm(
                formKey: widget.formKey,
                amountController: widget.amountController,
                addressController: widget.addressController,
                isDrain: widget.isDrain,
                btcAddressData: widget.btcAddressData,
                bitcoinCurrency: widget.bitcoinCurrency,
                paymentLimits: widget.paymentLimits,
                onChanged: (bool value) {
                  widget.onChanged(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
