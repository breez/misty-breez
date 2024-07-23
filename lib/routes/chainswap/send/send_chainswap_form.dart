import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/routes/chainswap/send/validator_holder.dart';
import 'package:l_breez/routes/chainswap/send/widgets/bitcoin_address_text_form_field.dart';
import 'package:l_breez/routes/chainswap/send/widgets/withdraw_funds_amount_text_form_field.dart';
import 'package:l_breez/routes/chainswap/send/withdraw_funds_model.dart';
import 'package:l_breez/widgets/amount_form_field/sat_amount_form_field_formatter.dart';
import 'package:logging/logging.dart';

final _log = Logger("SendChainSwapForm");

class SendChainSwapForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController addressController;
  final bool withdrawMaxValue;
  final ValueChanged<bool> onChanged;
  final BitcoinAddressData? btcAddressData;
  final BitcoinCurrency bitcoinCurrency;
  final OnchainPaymentLimitsResponse paymentLimits;

  const SendChainSwapForm({
    super.key,
    required this.formKey,
    required this.amountController,
    required this.addressController,
    required this.onChanged,
    required this.withdrawMaxValue,
    this.btcAddressData,
    required this.bitcoinCurrency,
    required this.paymentLimits,
  });

  @override
  State<SendChainSwapForm> createState() => _SendChainSwapFormState();
}

class _SendChainSwapFormState extends State<SendChainSwapForm> {
  final _validatorHolder = ValidatorHolder();

  @override
  void initState() {
    super.initState();
    if (widget.btcAddressData != null) {
      _fillBtcAddressData(widget.btcAddressData!);
    }
  }

  void _fillBtcAddressData(BitcoinAddressData addressData) {
    _log.info("Filling BTC Address data for ${addressData.address}");
    widget.addressController.text = addressData.address;
    if (addressData.amountSat != null) {
      _setAmount(addressData.amountSat!.toInt());
    }
  }

  void _setAmount(int amountSats) {
    setState(() {
      widget.amountController.text = widget.bitcoinCurrency
          .format(amountSats, includeDisplayName: false, userInput: true)
          .formatBySatAmountFormFieldFormatter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Form(
        key: widget.formKey,
        child: Column(
          children: [
            BitcoinAddressTextFormField(
              context: context,
              controller: widget.addressController,
              validatorHolder: _validatorHolder,
            ),
            WithdrawFundsAmountTextFormField(
              context: context,
              bitcoinCurrency: widget.bitcoinCurrency,
              controller: widget.amountController,
              withdrawMaxValue: widget.withdrawMaxValue,
              balance: widget.paymentLimits.send.maxSat,
              policy: WithdrawFundsPolicy(
                WithdrawKind.withdrawFunds,
                widget.paymentLimits.send.minSat,
                widget.paymentLimits.send.maxSat,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                texts.withdraw_funds_use_all_funds,
                style: const TextStyle(color: Colors.white),
                maxLines: 1,
              ),
              trailing: Switch(
                value: widget.withdrawMaxValue,
                activeColor: Colors.white,
                onChanged: (bool value) async {
                  setState(() {
                    widget.onChanged(value);
                    if (value) {
                      _setAmount(widget.paymentLimits.send.maxSat.toInt());
                    } else {
                      widget.amountController.text = "";
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
