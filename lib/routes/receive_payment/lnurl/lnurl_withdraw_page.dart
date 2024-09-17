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
import 'package:l_breez/routes/receive_payment/widgets/destination_widget/destination_widget.dart';
import 'package:l_breez/routes/receive_payment/widgets/payment_info_message_box/payment_fees_message_box.dart';
import 'package:l_breez/theme/src/theme.dart';
import 'package:l_breez/theme/src/theme_extensions.dart';
import 'package:l_breez/theme/theme.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchLightningLimits();
      _initializePageData();
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
    var minWithdrawableSat = widget.requestData.minWithdrawable.toInt() ~/ 1000;
    final effectiveMinSat = max(response.receive.minSat.toInt(), minWithdrawableSat);
    final maxWithdrawableSat = widget.requestData.maxWithdrawable.toInt() ~/ 1000;

    final effectiveMaxSat = min(response.receive.maxSat.toInt(), maxWithdrawableSat);
    if (effectiveMaxSat < effectiveMinSat) {
      final texts = context.texts();
      final currencyCubit = context.read<CurrencyCubit>();
      final currencyState = currencyCubit.state;

      final networkLimit = currencyState.bitcoinCurrency.format(
        effectiveMinSat,
        includeDisplayName: true,
      );
      final isFixedAmountWithinLimits = _isFixedAmount && (effectiveMinSat == effectiveMaxSat);
      if (!isFixedAmountWithinLimits) {
        final minWithdrawableFormatted = currencyState.bitcoinCurrency.format(maxWithdrawableSat);
        final maxWithdrawableFormatted = currencyState.bitcoinCurrency.format(maxWithdrawableSat);
        throw Exception(
          "Payment amount is outside the allowed limits, which range from $minWithdrawableFormatted to $maxWithdrawableFormatted",
        );
      }

      throw Exception(texts.invoice_payment_validator_error_payment_below_invoice_limit(networkLimit));
    }

    setState(() {
      _lightningLimits = response;
      _loading = false;
    });
  }

  void _initializePageData() {
    final data = widget.requestData;
    _isFixedAmount = data.minWithdrawable == data.maxWithdrawable;
    if (!_isFixedAmount) {
      if (_amountFocusNode.canRequestFocus) {
        _amountFocusNode.requestFocus();
      }
    }

    final currencyState = context.read<CurrencyCubit>().state;
    _amountController.text = currencyState.bitcoinCurrency.format(
      data.maxWithdrawable.toInt() ~/ 1000,
      includeDisplayName: false,
    );
    _descriptionController.text = data.defaultDescription;
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
                          autofocus: !(_isFixedAmount),
                          readOnly: _isFixedAmount,
                          controller: _amountController,
                          validatorFn: (v) => validatePayment(v),
                          style: FieldTextStyle.textStyle,
                        ),
                        (_isFixedAmount)
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: RichText(
                                  text: TextSpan(
                                    style: FieldTextStyle.labelStyle,
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: texts.lnurl_fetch_invoice_min(
                                          minWithdrawableFormatted,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => _pasteAmount(currencyState, minWithdrawable),
                                      ),
                                      TextSpan(
                                        text: texts.lnurl_fetch_invoice_and(maxWithdrawableFormatted),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => _pasteAmount(currencyState, maxWithdrawable),
                                      ),
                                    ],
                                  ),
                                ),
                              )
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

  String? validatePayment(int amount) {
    final currencyCubit = context.read<CurrencyCubit>();
    return PaymentValidator(
      validatePayment: _validatePayment,
      currency: currencyCubit.state.bitcoinCurrency,
      texts: context.texts(),
    ).validateIncoming(amount);
  }

  void _validatePayment(int amount, bool outgoing) {
    final accountState = context.read<AccountCubit>().state;
    final balance = accountState.balance;
    final lnUrlCubit = context.read<LnUrlCubit>();
    return lnUrlCubit.validateLnUrlPayment(BigInt.from(amount), outgoing, _lightningLimits!, balance);
  }

  void _pasteAmount(CurrencyState currencyState, int amount) {
    setState(() {
      _amountController.text = currencyState.bitcoinCurrency.format(
        amount,
        includeDisplayName: false,
        userInput: true,
      );
    });
  }
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
