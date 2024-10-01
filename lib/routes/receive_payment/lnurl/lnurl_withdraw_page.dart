import 'dart:math';

import 'package:breez_liquid/breez_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_page_result.dart';
import 'package:l_breez/routes/lnurl/withdraw/lnurl_withdraw_dialog.dart';
import 'package:l_breez/theme/src/theme.dart';
import 'package:l_breez/theme/src/theme_extensions.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/always_disabled_focus_node.dart';
import 'package:l_breez/utils/payment_validator.dart';
import 'package:l_breez/widgets/amount_form_field/amount_form_field.dart';
import 'package:l_breez/widgets/keyboard_done_action.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';
import 'package:logging/logging.dart';

final _log = Logger("LnUrlWithdrawPage");

class LnUrlWithdrawPage extends StatefulWidget {
  final Function(LNURLPageResult? result) onFinish;
  final LnUrlWithdrawRequestData requestData;

  static const routeName = "/lnurl_withdraw";
  static const paymentMethod = PaymentMethod.lightning;

  const LnUrlWithdrawPage({super.key, required this.onFinish, required this.requestData});

  @override
  State<StatefulWidget> createState() => LnUrlWithdrawPageState();
}

class LnUrlWithdrawPageState extends State<LnUrlWithdrawPage> {
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

    _isFixedAmount = widget.requestData.minWithdrawable == widget.requestData.maxWithdrawable;
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
    final minWithdrawableSat = widget.requestData.minWithdrawable.toInt() ~/ 1000;
    final maxWithdrawableSat = widget.requestData.maxWithdrawable.toInt() ~/ 1000;
    final effectiveMinSat = max(response.receive.minSat.toInt(), minWithdrawableSat);
    final effectiveMaxSat = min(response.receive.maxSat.toInt(), maxWithdrawableSat);

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

    _descriptionController.text = widget.requestData.defaultDescription;
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
      body: BlocBuilder<CurrencyCubit, CurrencyState>(
        builder: (context, currencyState) {
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

          final minWithdrawableSat = widget.requestData.minWithdrawable.toInt() ~/ 1000;
          final maxWithdrawableSat = widget.requestData.maxWithdrawable.toInt() ~/ 1000;
          final effectiveMinSat = max(_lightningLimits!.receive.minSat.toInt(), minWithdrawableSat);
          final effectiveMaxSat = min(_lightningLimits!.receive.maxSat.toInt(), maxWithdrawableSat);
          final effMinWithdrawableFormatted = currencyState.bitcoinCurrency.format(effectiveMinSat);
          final effMaxWithdrawableFormatted = currencyState.bitcoinCurrency.format(effectiveMaxSat);

          return Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.requestData.defaultDescription.isNotEmpty) ...[
                          TextFormField(
                            controller: _descriptionController,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.done,
                            maxLines: null,
                            readOnly: true,
                            focusNode: AlwaysDisabledFocusNode(),
                            decoration: InputDecoration(
                              labelText: texts.payment_details_dialog_action_for_payment_description,
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
                                      effMinWithdrawableFormatted,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => _pasteAmount(currencyState, effectiveMinSat),
                                  ),
                                  TextSpan(
                                    text: texts.lnurl_fetch_invoice_and(
                                      effMaxWithdrawableFormatted,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () => _pasteAmount(currencyState, effectiveMaxSat),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _loading
          ? null
          : (_errorMessage == null)
              ? SingleButtonBottomBar(
                  stickToBottom: true,
                  text: texts.invoice_action_redeem,
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _withdraw();
                    }
                  },
                )
              : SingleButtonBottomBar(
                  stickToBottom: true,
                  text: texts.qr_code_dialog_action_close,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
    );
  }

  Future<void> _withdraw() async {
    final data = widget.requestData;
    _log.info(
      "Withdraw request: description=${data.defaultDescription}, k1=${data.k1}, "
      "min=${data.minWithdrawable}, max=${data.maxWithdrawable}",
    );
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();

    final navigator = Navigator.of(context);
    navigator.pop();
    // TODO: Instead of showing LNURLWithdrawDialog. Call LNURL withdraw and consequently payment success animation.
    showDialog(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (_) => LNURLWithdrawDialog(
        requestData: data,
        amountSats: currencyCubit.state.bitcoinCurrency.parse(
          _amountController.text,
        ),
        onFinish: widget.onFinish,
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
      return texts.lnurl_withdraw_dialog_error_amount_exceeds(effectiveMaxSat);
    }

    if (amount < effectiveMinSat) {
      return texts.lnurl_withdraw_dialog_error_amount_below(effectiveMinSat);
    }

    return PaymentValidator(
      validatePayment: _validatePayment,
      currency: currencyState.bitcoinCurrency,
      texts: context.texts(),
    ).validateIncoming(amount);
  }

  void _validatePayment(int amount, bool outgoing) {
    final accountState = context.read<AccountCubit>().state;
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
