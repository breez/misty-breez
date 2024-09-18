import 'dart:convert';
import 'dart:math';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/lnurl/payment/lnurl_payment_info.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_metadata.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/always_disabled_focus_node.dart';
import 'package:l_breez/utils/payment_validator.dart';
import 'package:l_breez/widgets/amount_form_field/amount_form_field.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/keyboard_done_action.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';

class LnUrlPaymentPage extends StatefulWidget {
  final LnUrlPayRequestData requestData;

  const LnUrlPaymentPage({super.key, required this.requestData});

  @override
  State<StatefulWidget> createState() => LnUrlPaymentPageState();
}

class LnUrlPaymentPageState extends State<LnUrlPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  var _doneAction = KeyboardDoneAction();

  bool _isFixedAmount = false;
  bool _loading = true;
  String? _errorMessage;
  LightningPaymentLimitsResponse? _lightningLimits;

  @override
  void initState() {
    super.initState();
    _doneAction = KeyboardDoneAction(focusNodes: [_amountFocusNode]);

    _isFixedAmount = widget.requestData.minSendable == widget.requestData.maxSendable;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchLightningLimits();
    });
  }

  Future<void> _fetchLightningLimits() async {
    final paymentLimitsCubit = context.read<PaymentLimitsCubit>();
    try {
      final response = await paymentLimitsCubit.fetchLightningLimits();
      _handleLightningPaymentLimitsResponse(response);
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _loading = false;
      });
    }
  }

  void _handleLightningPaymentLimitsResponse(LightningPaymentLimitsResponse response) {
    final minSendableSat = widget.requestData.minSendable.toInt() ~/ 1000;
    final maxSendableSat = widget.requestData.maxSendable.toInt() ~/ 1000;
    final effectiveMinSat = max(response.send.minSat.toInt(), minSendableSat);
    final effectiveMaxSat = min(response.send.maxSat.toInt(), maxSendableSat);

    _validateEffectiveLimits(effectiveMinSat: effectiveMinSat, effectiveMaxSat: effectiveMaxSat);

    _updateFormFields(effectiveMaxSat: effectiveMaxSat);

    setState(() {
      _lightningLimits = response;
      _loading = false;
    });
  }

  void _validateEffectiveLimits({
    required int effectiveMinSat,
    required int effectiveMaxSat,
  }) {
    if (effectiveMaxSat < effectiveMinSat) {
      final texts = context.texts();
      final currencyCubit = context.read<CurrencyCubit>();
      final currencyState = currencyCubit.state;

      final isFixedAmountWithinLimits = _isFixedAmount && (effectiveMinSat == effectiveMaxSat);
      if (!isFixedAmountWithinLimits) {
        final effMinWithdrawableFormatted = currencyState.bitcoinCurrency.format(effectiveMinSat);
        final effMaxWithdrawableFormatted = currencyState.bitcoinCurrency.format(effectiveMaxSat);
        throw Exception(
          "Payment amount is outside the allowed limits, which range from $effMinWithdrawableFormatted to $effMaxWithdrawableFormatted",
        );
      }

      final networkLimit = currencyState.bitcoinCurrency.format(
        effectiveMinSat,
        includeDisplayName: true,
      );
      throw Exception(texts.invoice_payment_validator_error_payment_below_invoice_limit(networkLimit));
    }
  }

  void _updateFormFields({
    required int effectiveMaxSat,
  }) {
    if (_isFixedAmount) {
      final currencyCubit = context.read<CurrencyCubit>();
      final currencyState = currencyCubit.state;

      _amountController.text = currencyState.bitcoinCurrency.format(
        effectiveMaxSat,
        includeDisplayName: false,
      );
    } else if (_amountFocusNode.canRequestFocus) {
      _amountFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _doneAction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.lnurl_fetch_invoice_pay_to_payee(widget.requestData.domain)),
      ),
      body: BlocBuilder<CurrencyCubit, CurrencyState>(builder: (context, currencyState) {
        if (_loading) {
          final themeData = Theme.of(context);

          return Center(
            child: Loader(
              color: themeData.primaryColor.withOpacity(0.5),
            ),
          );
        }

        if (_errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final metadataMap = {
          for (var v in json.decode(widget.requestData.metadataStr)) v[0] as String: v[1],
        };
        String? base64String = metadataMap['image/png;base64'] ?? metadataMap['image/jpeg;base64'];

        final minSendableSat = widget.requestData.minSendable.toInt() ~/ 1000;
        final maxSendableSat = widget.requestData.maxSendable.toInt() ~/ 1000;
        final effectiveMinSat = max(_lightningLimits!.send.minSat.toInt(), minSendableSat);
        final effectiveMaxSat = min(_lightningLimits!.send.maxSat.toInt(), maxSendableSat);
        final effMinSendableFormatted = currencyState.bitcoinCurrency.format(effectiveMinSat);
        final effMaxSendableFormatted = currencyState.bitcoinCurrency.format(effectiveMaxSat);

        return Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.requestData.commentAllowed > 0) ...[
                  TextFormField(
                    controller: _descriptionController,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.done,
                    maxLines: null,
                    maxLength: widget.requestData.commentAllowed.toInt(),
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    decoration: InputDecoration(
                      labelText: texts.lnurl_payment_page_comment,
                    ),
                    style: FieldTextStyle.textStyle,
                  )
                ],
                AmountFormField(
                  context: context,
                  texts: texts,
                  bitcoinCurrency: currencyState.bitcoinCurrency,
                  focusNode: _isFixedAmount ? AlwaysDisabledFocusNode() : _amountFocusNode,
                  autofocus: !_isFixedAmount,
                  readOnly: _isFixedAmount,
                  controller: _amountController,
                  validatorFn: (amount) => validatePayment(
                    amount: amount,
                    effectiveMinSat: effectiveMinSat,
                    effectiveMaxSat: effectiveMaxSat,
                  ),
                  style: FieldTextStyle.textStyle,
                ),
                if (!_isFixedAmount) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: RichText(
                      text: TextSpan(
                        style: FieldTextStyle.labelStyle,
                        children: <TextSpan>[
                          TextSpan(
                            text: texts.lnurl_fetch_invoice_min(
                              effMinSendableFormatted,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _pasteAmount(currencyState, effectiveMinSat),
                          ),
                          TextSpan(
                            text: texts.lnurl_fetch_invoice_and(
                              effMaxSendableFormatted,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _pasteAmount(currencyState, effectiveMaxSat),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 48,
                  padding: const EdgeInsets.only(top: 16.0),
                  child: LNURLMetadataText(metadataMap: metadataMap),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 22),
                    child: Center(
                      child: LNURLMetadataImage(
                        base64String: base64String,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: _loading
          ? null
          : _errorMessage != null
              ? SingleButtonBottomBar(
                  stickToBottom: true,
                  text: texts.qr_code_dialog_action_close,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              : SingleButtonBottomBar(
                  stickToBottom: true,
                  text: texts.lnurl_fetch_invoice_action_continue,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final currencyCubit = context.read<CurrencyCubit>();
                      final amount = currencyCubit.state.bitcoinCurrency.parse(_amountController.text);
                      final comment = _descriptionController.text;
                      // TODO: Instead of popping LNURLPaymentInfo to show Processing Payment Dialog. Call LNURL pay and consequently payment success animation.
                      Navigator.pop(context, LNURLPaymentInfo(amount: amount, comment: comment));
                    }
                  },
                ),
    );
  }

  String? validatePayment({
    required int amount,
    required int effectiveMinSat,
    required int effectiveMaxSat,
  }) {
    final texts = context.texts();
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;

    if (amount > effectiveMaxSat) {
      return texts.lnurl_payment_page_error_exceeds_limit(effectiveMaxSat);
    }

    if (amount < effectiveMinSat) {
      return texts.lnurl_payment_page_error_below_limit(effectiveMinSat);
    }

    return PaymentValidator(
      validatePayment: _validatePayment,
      currency: currencyState.bitcoinCurrency,
      texts: context.texts(),
    ).validateOutgoing(amount);
  }

  void _validatePayment(int amount, bool outgoing) {
    final accountCubit = context.read<AccountCubit>();
    final accountState = accountCubit.state;
    final balance = accountState.balance;
    final lnUrlCubit = context.read<LnUrlCubit>();
    return lnUrlCubit.validateLnUrlPayment(BigInt.from(amount), outgoing, _lightningLimits!, balance);
  }

  void _pasteAmount(CurrencyState currencyState, int amountSat) {
    setState(() {
      _amountController.text = currencyState.bitcoinCurrency.format(
        amountSat,
        includeDisplayName: false,
      );
    });
  }
}
