import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/currency.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('SendChainSwapForm');

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
    required this.formKey,
    required this.amountController,
    required this.addressController,
    required this.onChanged,
    required this.withdrawMaxValue,
    required this.bitcoinCurrency,
    required this.paymentLimits,
    super.key,
    this.btcAddressData,
  });

  @override
  State<SendChainSwapForm> createState() => _SendChainSwapFormState();
}

class _SendChainSwapFormState extends State<SendChainSwapForm> {
  final ValidatorHolder _validatorHolder = ValidatorHolder();

  @override
  void initState() {
    super.initState();
    if (widget.btcAddressData != null) {
      _fillBtcAddressData(widget.btcAddressData!);
    }
  }

  void _fillBtcAddressData(BitcoinAddressData addressData) {
    _logger.info('Filling BTC Address data for ${addressData.address}');
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
    final BreezTranslations texts = context.texts();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Form(
        key: widget.formKey,
        child: Column(
          children: <Widget>[
            BitcoinAddressTextFormField(
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
                      final AccountCubit accountCubit = context.read<AccountCubit>();
                      final AccountState accountState = accountCubit.state;
                      _setAmount(accountState.walletInfo!.balanceSat.toInt());
                    } else {
                      widget.amountController.text = '';
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
