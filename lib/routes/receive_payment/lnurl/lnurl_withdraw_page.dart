import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/services/services.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:provider/provider.dart';

export 'widgets/widgets.dart';

final Logger _logger = Logger('LnUrlWithdrawPage');

class LnUrlWithdrawPage extends StatefulWidget {
  final Function(LNURLPageResult? result) onFinish;
  final LnUrlWithdrawRequestData requestData;

  static const String routeName = '/lnurl_withdraw';
  static const PaymentMethod paymentMethod = PaymentMethod.lightning;

  const LnUrlWithdrawPage({
    required this.onFinish,
    required this.requestData,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => LnUrlWithdrawPageState();
}

class LnUrlWithdrawPageState extends State<LnUrlWithdrawPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _descriptionFocusNode = FocusNode();

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
        errorMessage = ExceptionHandler.extractMessage(error, getSystemAppLocalizations());
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
            return const CenteredLoader();
          }

          if (_lightningLimits == null) {
            if (errorMessage.isEmpty) {
              return const CenteredLoader();
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
            padding: const EdgeInsets.only(top: 32, bottom: 40.0),
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
                            padding: const EdgeInsets.only(bottom: 32),
                            child: LnWithdrawHeader(
                              callback: widget.requestData.callback,
                              amountSat: minWithdrawableSat,
                              errorMessage: errorMessage,
                            ),
                          ),
                        ],
                        Container(
                          decoration: ShapeDecoration(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            color: themeData.customData.surfaceBgColor,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 32,
                            horizontal: 24,
                          ),
                          child: Column(
                            children: <Widget>[
                              TextFormField(
                                focusNode: _descriptionFocusNode,
                                controller: _descriptionController,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.done,
                                maxLines: null,
                                maxLength: 90,
                                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                                decoration: InputDecoration(
                                  prefixIconConstraints: BoxConstraints.tight(
                                    const Size(16, 56),
                                  ),
                                  prefixIcon: const SizedBox.shrink(),
                                  contentPadding: const EdgeInsets.only(
                                    left: 16,
                                    top: 16,
                                    bottom: 16,
                                  ),
                                  border: const OutlineInputBorder(),
                                  labelText: texts.invoice_description_label,
                                  counterStyle: _descriptionFocusNode.hasFocus
                                      ? focusedCounterTextStyle
                                      : counterTextStyle,
                                ),
                                style: FieldTextStyle.textStyle,
                              ),
                              if (!_isFixedAmount) ...<Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const SizedBox(height: 16.0),
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
                                          final int amountSat =
                                              currencyState.bitcoinCurrency.parse(amountStr);
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
                                      errorStyle: FieldTextStyle.labelStyle.copyWith(
                                        fontSize: 18.0,
                                        color: themeData.colorScheme.error,
                                      ),
                                    ),
                                    if (!_isFormEnabled) ...<Widget>[
                                      const SizedBox(height: 8.0),
                                      AutoSizeText(
                                        errorMessage,
                                        maxLines: 3,
                                        textAlign: TextAlign.left,
                                        style: FieldTextStyle.labelStyle.copyWith(
                                          fontSize: 18.0,
                                          color: themeData.colorScheme.error,
                                        ),
                                      ),
                                    ],
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: LnUrlWithdrawLimits(
                                        limitsResponse: _lightningLimits,
                                        minWithdrawableSat: minWithdrawableSat,
                                        maxWithdrawableSat: maxWithdrawableSat,
                                        onTap: _isFormEnabled
                                            ? (int amountSat) async {
                                                _amountFocusNode.unfocus();
                                                setState(() {
                                                  _amountController.text =
                                                      currencyState.bitcoinCurrency.format(
                                                    amountSat,
                                                    includeDisplayName: false,
                                                  );
                                                });
                                                _formKey.currentState?.validate();
                                              }
                                            : (int amountSat) async {
                                                return;
                                              },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ].expand((Widget widget) sync* {
                              yield widget;
                              yield const Divider(
                                height: 32.0,
                                color: Color.fromRGBO(40, 59, 74, 0.5),
                                indent: 0.0,
                                endIndent: 0.0,
                              );
                            }).toList()
                              ..removeLast(),
                          ),
                        ),
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
              : SingleButtonBottomBar(
                  stickToBottom: true,
                  text: texts.invoice_action_redeem,
                  enabled: (!_isFixedAmount && _isFormEnabled) || (_isFixedAmount && errorMessage.isEmpty),
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
    showRedeemingFundsSheet(
      context,
      requestData: data,
      amountSats: currencyCubit.state.bitcoinCurrency.parse(
        _amountController.text,
      ),
      onFinish: widget.onFinish,
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
      message = texts.invoice_payment_validator_error_payment_below_invoice_limit(
        networkLimit,
      );
      setState(() {
        _isFormEnabled = false;
      });
    } else if (amountSat > effectiveMaxSat) {
      final String networkLimit = '(${currencyState.bitcoinCurrency.format(
        effectiveMaxSat,
      )})';
      message = throwError
          ? texts.valid_payment_error_exceeds_the_limit(networkLimit)
          : '${texts.lnurl_withdraw_dialog_error_amount_exceeds(effectiveMaxSat)} ${currencyState.bitcoinCurrency.displayName}';
    } else if (amountSat < effectiveMinSat) {
      final String effMinSendableFormatted = currencyState.bitcoinCurrency.format(effectiveMinSat);
      message = throwError
          ? '${texts.invoice_payment_validator_error_payment_below_invoice_limit(effMinSendableFormatted)}.'
          : '${texts.lnurl_withdraw_dialog_error_amount_below(effectiveMinSat)} ${currencyState.bitcoinCurrency.displayName}';
    } else {
      message = PaymentValidator(
        validatePayment: _validateLnUrlWithdraw,
        currency: currencyState.bitcoinCurrency,
        texts: context.texts(),
      ).validateIncoming(amountSat);
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
    final LnUrlService lnUrlService = Provider.of<LnUrlService>(context, listen: false);
    return lnUrlService.validateLnUrlPayment(
      amount: BigInt.from(amount),
      outgoing: outgoing,
      lightningLimits: _lightningLimits!,
      balance: balance,
    );
  }
}
