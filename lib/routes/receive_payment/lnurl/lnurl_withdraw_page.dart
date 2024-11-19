import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_liquid/breez_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
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

final Logger _logger = Logger('LnUrlWithdrawPage');

class LnUrlWithdrawPage extends StatefulWidget {
  final Function(LNURLPageResult? result) onFinish;
  final LnUrlWithdrawRequestData requestData;

  static const String routeName = '/lnurl_withdraw';
  static const PaymentMethod paymentMethod = PaymentMethod.lightning;

  const LnUrlWithdrawPage({required this.onFinish, required this.requestData, super.key});

  @override
  State<StatefulWidget> createState() => LnUrlWithdrawPageState();
}

class LnUrlWithdrawPageState extends State<LnUrlWithdrawPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  KeyboardDoneAction _doneAction = KeyboardDoneAction();

  bool _isFixedAmount = false;
  bool _isLoading = true;
  bool _isFormEnabled = true;
  String errorMessage = '';
  LightningPaymentLimitsResponse? _lightningLimits;

  @override
  void initState() {
    super.initState();
    _doneAction = KeyboardDoneAction(focusNodes: <FocusNode>[_amountFocusNode]);

    _isFixedAmount = widget.requestData.minWithdrawable == widget.requestData.maxWithdrawable;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchLightningLimits();
    });
  }

  Future<void> _fetchLightningLimits() async {
    setState(() {
      _isLoading = true;
      errorMessage = '';
    });
    final PaymentLimitsCubit paymentLimitsCubit = context.read<PaymentLimitsCubit>();
    try {
      final LightningPaymentLimitsResponse? response = await paymentLimitsCubit.fetchLightningLimits();
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
      final int minNetworkLimit = _lightningLimits!.receive.minSat.toInt();
      final int maxNetworkLimit = _lightningLimits!.receive.maxSat.toInt();
      final int minWithdrawableSat = widget.requestData.minWithdrawable.toInt() ~/ 1000;
      final int maxWithdrawableSat = widget.requestData.maxWithdrawable.toInt() ~/ 1000;
      final int effectiveMinSat = min(
        max(minNetworkLimit, minWithdrawableSat),
        maxNetworkLimit,
      );
      final int rawMaxSat = min(maxNetworkLimit, maxWithdrawableSat);
      final int effectiveMaxSat = max(minNetworkLimit, rawMaxSat);
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
      final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
      final CurrencyState currencyState = currencyCubit.state;

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
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      body: BlocBuilder<CurrencyCubit, CurrencyState>(
        builder: (BuildContext context, CurrencyState currencyState) {
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

          final int minNetworkLimit = _lightningLimits!.receive.minSat.toInt();
          final int maxNetworkLimit = _lightningLimits!.receive.maxSat.toInt();
          final int minWithdrawableSat = widget.requestData.minWithdrawable.toInt() ~/ 1000;
          final int maxWithdrawableSat = widget.requestData.maxWithdrawable.toInt() ~/ 1000;
          final int effectiveMinSat = min(
            max(minNetworkLimit, minWithdrawableSat),
            maxNetworkLimit,
          );
          final int effectiveMaxSat = max(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (_isFixedAmount) ...<Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: LnWithdrawHeader(
                              callback: widget.requestData.callback,
                              amountSat: minWithdrawableSat,
                              errorMessage: errorMessage,
                            ),
                          ),
                        ],
                        if (!_isFixedAmount) ...<Widget>[
                          AmountFormField(
                            context: context,
                            texts: texts,
                            bitcoinCurrency: currencyState.bitcoinCurrency,
                            focusNode: _amountFocusNode,
                            autofocus: _isFormEnabled && errorMessage.isEmpty,
                            enabled: _isFormEnabled,
                            enableInteractiveSelection: _isFormEnabled,
                            controller: _amountController,
                            validatorFn: (int amountSat) => validatePayment(
                              amountSat: amountSat,
                              effectiveMinSat: effectiveMinSat,
                              effectiveMaxSat: effectiveMaxSat,
                            ),
                            returnFN: (String amountStr) async {
                              if (amountStr.isNotEmpty) {
                                final int amountSat = currencyState.bitcoinCurrency.parse(amountStr);
                                setState(() {
                                  _amountController.text = currencyState.bitcoinCurrency.format(
                                    amountSat,
                                    includeDisplayName: false,
                                  );
                                });
                                _formKey.currentState?.validate();
                              }
                            },
                            onFieldSubmitted: (String amountStr) async {
                              if (amountStr.isNotEmpty) {
                                _formKey.currentState?.validate();
                              }
                            },
                            style: FieldTextStyle.textStyle,
                            errorMaxLines: 3,
                          ),
                        ],
                        if (!_isFixedAmount) ...<Widget>[
                          const SizedBox(height: 8.0),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: LnUrlWithdrawLimits(
                              limitsResponse: _lightningLimits,
                              minWithdrawableSat: minWithdrawableSat,
                              maxWithdrawableSat: maxWithdrawableSat,
                              onTap: (int amountSat) async {
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
                        if (!_isFormEnabled || _isFixedAmount && errorMessage.isNotEmpty) ...<Widget>[
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
                        if (widget.requestData.defaultDescription.isNotEmpty) ...<Widget>[
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
    final LnUrlWithdrawRequestData data = widget.requestData;
    _logger.info(
      'Withdraw request: description=${data.defaultDescription}, k1=${data.k1}, '
      'min=${data.minWithdrawable}, max=${data.maxWithdrawable}',
    );
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();

    final NavigatorState navigator = Navigator.of(context);
    navigator.pop();
    // TODO(erdemyerebasmaz): Instead of showing LNURLWithdrawDialog. Call LNURL withdraw and consequently payment success animation.
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
    required int effectiveMaxSat,
    int? rawMaxSat,
    bool throwError = false,
  }) {
    final BreezTranslations texts = context.texts();
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;

    String? message;
    if (_lightningLimits == null) {
      message = texts.payment_limits_fetch_error_message;
    }

    if (!_isFixedAmount && effectiveMinSat == effectiveMaxSat) {
      final int minNetworkLimit = _lightningLimits!.receive.minSat.toInt();
      final int maxNetworkLimit = _lightningLimits!.receive.maxSat.toInt();
      final String minNetworkLimitFormatted = currencyState.bitcoinCurrency.format(minNetworkLimit);
      final String maxNetworkLimitFormatted = currencyState.bitcoinCurrency.format(maxNetworkLimit);
      message = texts.invoice_payment_validator_error_payment_outside_network_limits(
        minNetworkLimitFormatted,
        maxNetworkLimitFormatted,
      );
      setState(() {
        _isFormEnabled = false;
      });
    } else if (rawMaxSat != null && rawMaxSat < effectiveMinSat) {
      final String networkLimit = currencyState.bitcoinCurrency.format(
        effectiveMinSat,
      );
      message = texts.invoice_payment_validator_error_payment_below_invoice_limit(networkLimit);
      setState(() {
        _isFormEnabled = false;
      });
    } else if (amountSat > effectiveMaxSat) {
      final String networkLimit = '(${currencyState.bitcoinCurrency.format(
        effectiveMaxSat,
      )})';
      message = throwError
          ? texts.valid_payment_error_exceeds_the_limit(networkLimit)
          : texts.lnurl_withdraw_dialog_error_amount_exceeds(effectiveMaxSat);
    } else if (amountSat < effectiveMinSat) {
      final String effMinSendableFormatted = currencyState.bitcoinCurrency.format(effectiveMinSat);
      message = throwError
          ? '${texts.invoice_payment_validator_error_payment_below_invoice_limit(effMinSendableFormatted)}.'
          : texts.lnurl_withdraw_dialog_error_amount_below(effectiveMinSat);
    } else {
      message = PaymentValidator(
        validatePayment: _validateLnUrlWithdraw,
        currency: currencyState.bitcoinCurrency,
        texts: context.texts(),
      ).validateOutgoing(amountSat);
    }
    setState(() {
      errorMessage = message ?? '';
    });
    if (message != null && throwError) {
      throw message;
    }
    return message;
  }

  void _validateLnUrlWithdraw(int amount, bool outgoing) {
    final AccountState accountState = context.read<AccountCubit>().state;
    final int balance = accountState.walletInfo!.balanceSat.toInt();
    final LnUrlCubit lnUrlCubit = context.read<LnUrlCubit>();
    return lnUrlCubit.validateLnUrlPayment(BigInt.from(amount), outgoing, _lightningLimits!, balance);
  }
}
