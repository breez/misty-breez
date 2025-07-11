import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

final Logger _logger = Logger('SendChainSwapForm');

class SendChainSwapForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController addressController;
  final bool isDrain;
  final ValueChanged<bool> onChanged;
  final BitcoinAddressData? btcAddressData;
  final BitcoinCurrency bitcoinCurrency;
  final OnchainPaymentLimitsResponse paymentLimits;

  const SendChainSwapForm({
    required this.formKey,
    required this.amountController,
    required this.addressController,
    required this.onChanged,
    required this.isDrain,
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
  final FocusNode _amountFocusNode = FocusNode();
  KeyboardDoneAction _doneAction = KeyboardDoneAction();

  @override
  void initState() {
    super.initState();
    if (widget.btcAddressData != null) {
      _fillBtcAddressData(widget.btcAddressData!);
    }

    _doneAction = KeyboardDoneAction(focusNodes: <FocusNode>[_amountFocusNode]);
  }

  @override
  void dispose() {
    _doneAction.dispose();
    super.dispose();
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
    final AccountState accountState = context.watch<AccountCubit>().state;
    final CurrencyState currencyState = context.watch<CurrencyCubit>().state;

    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          BitcoinAddressTextFormField(
            controller: widget.addressController,
            validatorHolder: _validatorHolder,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 32.0, color: Color.fromRGBO(40, 59, 74, 0.5), indent: 0.0, endIndent: 0.0),
          ),
          WithdrawFundsAmountTextFormField(
            context: context,
            bitcoinCurrency: widget.bitcoinCurrency,
            controller: widget.amountController,
            focusNode: _amountFocusNode,
            isDrain: widget.isDrain,
            balance: accountState.walletInfo!.balanceSat,
            policy: WithdrawFundsPolicy(
              WithdrawKind.withdrawFunds,
              widget.paymentLimits.send.minSat,
              widget.paymentLimits.send.maxSat,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: AutoSizeText(
              texts.invoice_min_payment_limit(
                widget.bitcoinCurrency.format(widget.paymentLimits.send.minSat.toInt()),
              ),
              style: paymentLimitInformationTextStyle,
              maxLines: 1,
              minFontSize: MinFontSize(context).minFontSize,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Divider(height: 32.0, color: Color.fromRGBO(40, 59, 74, 0.5), indent: 0.0, endIndent: 0.0),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            minTileHeight: 0,
            title: Text(
              texts.withdraw_funds_use_all_funds,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                height: 1.208,
                fontWeight: FontWeight.w400,
                fontFamily: 'IBMPlexSans',
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${texts.available_balance_label} ${currencyState.bitcoinCurrency.format(accountState.walletInfo!.balanceSat.toInt())}',
                style: const TextStyle(
                  color: Color.fromRGBO(182, 188, 193, 1),
                  fontSize: 16,
                  height: 1.182,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'IBMPlexSans',
                ),
              ),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Switch(
                value: widget.isDrain,
                activeColor: Colors.white,
                activeTrackColor: themeData.primaryColor,
                onChanged: (bool value) async {
                  setState(() {
                    widget.onChanged(value);
                    if (value) {
                      final String formattedAmount = currencyState.bitcoinCurrency
                          .format(
                            accountState.walletInfo!.balanceSat.toInt(),
                            includeDisplayName: false,
                            userInput: true,
                          )
                          .formatBySatAmountFormFieldFormatter();
                      setState(() {
                        widget.amountController.text = formattedAmount;
                      });
                    } else {
                      widget.amountController.text = '';
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
