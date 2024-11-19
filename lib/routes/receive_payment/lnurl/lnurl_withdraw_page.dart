import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_liquid/breez_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/lnurl/payment/widgets/widgets.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_page_result.dart';
import 'package:l_breez/routes/lnurl/withdraw/lnurl_withdraw_dialog.dart';
import 'package:l_breez/routes/lnurl/withdraw/widgets/lnurl_withdraw_header.dart';
import 'package:l_breez/routes/receive_payment/lnurl/widgets/lnurl_withdraw_limits.dart';
import 'package:l_breez/theme/src/theme.dart';
import 'package:l_breez/theme/src/theme_extensions.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/utils/payment_validator.dart';
import 'package:l_breez/widgets/amount_form_field/amount_form_field.dart';
import 'package:l_breez/widgets/keyboard_done_action.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/scrollable_error_message_widget.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';
import 'package:logging/logging.dart';

final _logger = Logger("LnUrlWithdrawPage");

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
  bool _isLoading = true;
  bool _isFormEnabled = true;
  String errorMessage = "";
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
    setState(() {
      _isLoading = true;
      errorMessage = "";
    });
    final paymentLimitsCubit = context.read<PaymentLimitsCubit>();
    try {
      final response = await paymentLimitsCubit.fetchLightningLimits();
      setState(() {
        _lightningLimits = response;
      });
      await _handleLightningPaymentLimitsResponse();
    } catch (error) {
      setState(() {
        errorMessage = extractExceptionMessage(error, getSystemAppLocalizations());
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLightningPaymentLimitsResponse() async {
    try {
      final minNetworkLimit = _lightningLimits!.receive.minSat.toInt();
      final maxNetworkLimit = _lightningLimits!.receive.maxSat.toInt();
      final minWithdrawableSat = widget.requestData.minWithdrawable.toInt() ~/ 1000;
      final maxWithdrawableSat = widget.requestData.maxWithdrawable.toInt() ~/ 1000;
      final effectiveMinSat = min(
        max(minNetworkLimit, minWithdrawableSat),
        maxNetworkLimit,
      );
      final rawMaxSat = min(maxNetworkLimit, maxWithdrawableSat);
      final effectiveMaxSat = max(minNetworkLimit, rawMaxSat);
      _updateFormFields(
        amountSat: _isFixedAmount ? minWithdrawableSat : effectiveMinSat,
      );
      validatePayment(
        amountSat: _isFixedAmount ? minWithdrawableSat : effectiveMinSat,
        effectiveMinSat: effectiveMinSat,
        rawMaxSat: rawMaxSat,
        effectiveMaxSat: effectiveMaxSat,
        throwError: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  void _updateFormFields({
    required int amountSat,
  }) {
    if (_isFixedAmount) {
      final currencyCubit = context.read<CurrencyCubit>();
      final currencyState = currencyCubit.state;

      _amountController.text = currencyState.bitcoinCurrency.format(
        amountSat,
        includeDisplayName: false,
      );
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
    final themeData = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      body: BlocBuilder<CurrencyCubit, CurrencyState>(
        builder: (context, currencyState) {
          if (_isLoading) {
            return Center(
              child: Loader(
                color: themeData.primaryColor.withOpacity(0.5),
              ),
            );
          }

          if (_lightningLimits == null) {
            if (errorMessage.isEmpty) {
              return Center(
                child: Loader(
                  color: themeData.primaryColor.withOpacity(0.5),
                ),
              );
            }
            return ScrollableErrorMessageWidget(
              title: texts.payment_limits_generic_error_title,
              message: texts.payment_limits_generic_error_message(errorMessage),
            );
          }

          final minNetworkLimit = _lightningLimits!.receive.minSat.toInt();
          final maxNetworkLimit = _lightningLimits!.receive.maxSat.toInt();
          final minWithdrawableSat = widget.requestData.minWithdrawable.toInt() ~/ 1000;
          final maxWithdrawableSat = widget.requestData.maxWithdrawable.toInt() ~/ 1000;
          final effectiveMinSat = min(
            max(minNetworkLimit, minWithdrawableSat),
            maxNetworkLimit,
          );
          final effectiveMaxSat = max(
            minNetworkLimit,
            min(maxNetworkLimit, maxWithdrawableSat),
          );

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
                        if (_isFixedAmount) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: LnWithdrawHeader(
                              callback: widget.requestData.callback,
                              amountSat: minWithdrawableSat,
                              errorMessage: errorMessage,
                            ),
                          ),
                        ],
                        if (!_isFixedAmount) ...[
                          AmountFormField(
                            context: context,
                            texts: texts,
                            bitcoinCurrency: currencyState.bitcoinCurrency,
                            focusNode: _amountFocusNode,
                            autofocus: _isFormEnabled && errorMessage.isEmpty,
                            enabled: _isFormEnabled,
                            enableInteractiveSelection: _isFormEnabled,
                            controller: _amountController,
                            validatorFn: (amountSat) => validatePayment(
                              amountSat: amountSat,
                              effectiveMinSat: effectiveMinSat,
                              effectiveMaxSat: effectiveMaxSat,
                            ),
                            returnFN: (amountStr) async {
                              if (amountStr.isNotEmpty) {
                                final amountSat = currencyState.bitcoinCurrency.parse(amountStr);
                                setState(() {
                                  _amountController.text = currencyState.bitcoinCurrency.format(
                                    amountSat,
                                    includeDisplayName: false,
                                  );
                                });
                                _formKey.currentState?.validate();
                              }
                            },
                            onFieldSubmitted: (amountStr) async {
                              if (amountStr.isNotEmpty) {
                                _formKey.currentState?.validate();
                              }
                            },
                            style: FieldTextStyle.textStyle,
                            errorMaxLines: 3,
                          ),
                        ],
                        if (!_isFixedAmount) ...[
                          const SizedBox(height: 8.0),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: LnUrlWithdrawLimits(
                              limitsResponse: _lightningLimits,
                              minWithdrawableSat: minWithdrawableSat,
                              maxWithdrawableSat: maxWithdrawableSat,
                              onTap: (amountSat) async {
                                _amountFocusNode.unfocus();
                                setState(() {
                                  _amountController.text = currencyState.bitcoinCurrency.format(
                                    amountSat,
                                    includeDisplayName: false,
                                  );
                                });
                                _formKey.currentState?.validate();
                              },
                            ),
                          ),
                        ],
                        if (!_isFormEnabled || _isFixedAmount && errorMessage.isNotEmpty) ...[
                          const SizedBox(height: 8.0),
                          AutoSizeText(
                            errorMessage,
                            maxLines: 3,
                            textAlign: TextAlign.left,
                            style: FieldTextStyle.labelStyle.copyWith(
                              color: themeData.colorScheme.error,
                            ),
                          ),
                        ],
                        if (widget.requestData.defaultDescription.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: LnPaymentDescription(
                              metadataText: widget.requestData.defaultDescription,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _isLoading
          ? null
          : _lightningLimits == null
              ? SingleButtonBottomBar(
                  stickToBottom: true,
                  text: texts.invoice_ln_address_action_retry,
                  onPressed: () {
                    _fetchLightningLimits();
                  },
                )
              : !_isFormEnabled || _isFixedAmount && errorMessage.isNotEmpty
                  ? SingleButtonBottomBar(
                      stickToBottom: true,
                      text: texts.qr_code_dialog_action_close,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  : SingleButtonBottomBar(
                      stickToBottom: true,
                      text: texts.invoice_action_redeem,
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _withdraw();
                        }
                      },
                    ),
    );
  }

  Future<void> _withdraw() async {
    final data = widget.requestData;
    _logger.info(
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
    required int amountSat,
    required int effectiveMinSat,
    int? rawMaxSat,
    required int effectiveMaxSat,
    bool throwError = false,
  }) {
    final texts = context.texts();
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;

    String? message;
    if (_lightningLimits == null) {
      message = texts.payment_limits_fetch_error_message;
    }

    if (!_isFixedAmount && effectiveMinSat == effectiveMaxSat) {
      final minNetworkLimit = _lightningLimits!.receive.minSat.toInt();
      final maxNetworkLimit = _lightningLimits!.receive.maxSat.toInt();
      final minNetworkLimitFormatted = currencyState.bitcoinCurrency.format(minNetworkLimit);
      final maxNetworkLimitFormatted = currencyState.bitcoinCurrency.format(maxNetworkLimit);
      message = texts.invoice_payment_validator_error_payment_outside_network_limits(
        minNetworkLimitFormatted,
        maxNetworkLimitFormatted,
      );
      setState(() {
        _isFormEnabled = false;
      });
    } else if (rawMaxSat != null && rawMaxSat < effectiveMinSat) {
      final networkLimit = currencyState.bitcoinCurrency.format(
        effectiveMinSat,
        includeDisplayName: true,
      );
      message = texts.invoice_payment_validator_error_payment_below_invoice_limit(networkLimit);
      setState(() {
        _isFormEnabled = false;
      });
    } else if (amountSat > effectiveMaxSat) {
      final networkLimit = "(${currencyState.bitcoinCurrency.format(
        effectiveMaxSat,
        includeDisplayName: true,
      )})";
      message = throwError
          ? texts.valid_payment_error_exceeds_the_limit(networkLimit)
          : texts.lnurl_withdraw_dialog_error_amount_exceeds(effectiveMaxSat);
    } else if (amountSat < effectiveMinSat) {
      final effMinSendableFormatted = currencyState.bitcoinCurrency.format(effectiveMinSat);
      message = throwError
          ? "${texts.invoice_payment_validator_error_payment_below_invoice_limit(effMinSendableFormatted)}."
          : texts.lnurl_withdraw_dialog_error_amount_below(effectiveMinSat);
    } else {
      message = PaymentValidator(
        validatePayment: _validateLnUrlWithdraw,
        currency: currencyState.bitcoinCurrency,
        texts: context.texts(),
      ).validateOutgoing(amountSat);
    }
    setState(() {
      errorMessage = message ?? "";
    });
    if (message != null && throwError) {
      throw message;
    }
    return message;
  }

  void _validateLnUrlWithdraw(int amount, bool outgoing) {
    final accountState = context.read<AccountCubit>().state;
    final balance = accountState.walletInfo!.balanceSat.toInt();
    final lnUrlCubit = context.read<LnUrlCubit>();
    return lnUrlCubit.validateLnUrlPayment(BigInt.from(amount), outgoing, _lightningLimits!, balance);
  }
}
