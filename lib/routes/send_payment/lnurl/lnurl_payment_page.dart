import 'dart:convert';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/utils/payment_validator.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/widgets.dart';
import 'package:service_injector/service_injector.dart';

export 'widgets/widgets.dart';

class LnUrlPaymentPage extends StatefulWidget {
  final bool isConfirmation;
  final LnUrlPayRequestData requestData;
  final String? comment;

  static const String routeName = '/lnurl_payment';
  static const PaymentMethod paymentMethod = PaymentMethod.lightning;

  const LnUrlPaymentPage({required this.requestData, super.key, this.isConfirmation = false, this.comment});

  @override
  State<StatefulWidget> createState() => LnUrlPaymentPageState();
}

class LnUrlPaymentPageState extends State<LnUrlPaymentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  KeyboardDoneAction _doneAction = KeyboardDoneAction();

  bool _isFixedAmount = false;
  bool _isLoading = true;
  bool _isFormEnabled = true;
  bool _isCalculatingFees = false;
  String errorMessage = '';
  LightningPaymentLimitsResponse? _lightningLimits;

  PrepareLnUrlPayResponse? _prepareResponse;

  @override
  void initState() {
    super.initState();
    _doneAction = KeyboardDoneAction(focusNodes: <FocusNode>[_amountFocusNode]);

    _isFixedAmount = widget.requestData.minSendable == widget.requestData.maxSendable;
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
      final BreezTranslations texts = getSystemAppLocalizations();
      String message = extractExceptionMessage(error, texts);
      if (error is LnUrlPayError_ServiceConnectivity) {
        message = texts.lnurl_fetch_invoice_error_message(
          widget.requestData.domain,
          message,
        );
      }
      setState(() {
        errorMessage = message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLightningPaymentLimitsResponse() async {
    final int minNetworkLimit = _lightningLimits!.send.minSat.toInt();
    final int maxNetworkLimit = _lightningLimits!.send.maxSat.toInt();
    final int minSendableSat = widget.requestData.minSendable.toInt() ~/ 1000;
    final int maxSendableSat = widget.requestData.maxSendable.toInt() ~/ 1000;
    final int effectiveMinSat = min(
      max(minNetworkLimit, minSendableSat),
      maxNetworkLimit,
    );
    final int rawMaxSat = min(maxNetworkLimit, maxSendableSat);
    final int effectiveMaxSat = max(minNetworkLimit, rawMaxSat);
    _updateFormFields(amountSat: minSendableSat);
    final String? errorMessage = validatePayment(
      amountSat: _isFixedAmount ? minSendableSat : effectiveMinSat,
      effectiveMinSat: effectiveMinSat,
      rawMaxSat: rawMaxSat,
      effectiveMaxSat: effectiveMaxSat,
      throwError: true,
    );
    _updateFormFields(amountSat: effectiveMinSat);
    if (errorMessage == null && _isFixedAmount) {
      await _prepareLnUrlPayment(rawMaxSat);
    }
  }

  void _updateFormFields({
    required int amountSat,
  }) {
    if (!_isFixedAmount) {
      final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
      final CurrencyState currencyState = currencyCubit.state;

      _amountController.text = currencyState.bitcoinCurrency.format(
        amountSat,
        includeDisplayName: false,
      );
    }
    _descriptionController.text = widget.comment ?? '';
  }

  Future<void> _prepareLnUrlPayment(int amountSat) async {
    final BreezTranslations texts = context.texts();
    final LnUrlCubit lnUrlCubit = context.read<LnUrlCubit>();
    try {
      setState(() {
        _isCalculatingFees = true;
        _prepareResponse = null;
        errorMessage = '';
      });
      final PrepareLnUrlPayRequest req = PrepareLnUrlPayRequest(
        data: widget.requestData,
        amountMsat: BigInt.from(amountSat * 1000),
        validateSuccessActionUrl: false,
      );
      final PrepareLnUrlPayResponse response = await lnUrlCubit.prepareLnurlPay(req: req);
      setState(() {
        _prepareResponse = response;
      });
    } catch (error) {
      setState(() {
        _prepareResponse = null;
        errorMessage = extractExceptionMessage(error, texts);
        _isLoading = false;
      });
      rethrow;
    } finally {
      setState(() {
        _isCalculatingFees = false;
      });
      _formKey.currentState?.validate();
    }
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
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.lnurl_fetch_invoice_pay_to_payee(widget.requestData.domain)),
      ),
      body: BlocBuilder<CurrencyCubit, CurrencyState>(
        builder: (BuildContext context, CurrencyState currencyState) {
          if (_isLoading) {
            return Center(
              child: Loader(
                color: themeData.primaryColor.withOpacity(0.5),
              ),
            );
          }

          final Map<String, dynamic> metadataMap = <String, dynamic>{
            for (dynamic v in json.decode(widget.requestData.metadataStr)) v[0] as String: v[1],
          };
          final String? base64String = metadataMap['image/png;base64'] ?? metadataMap['image/jpeg;base64'];
          final String payeeName = metadataMap['text/identifier'] ?? widget.requestData.domain;
          final String? metadataText = metadataMap['text/long-desc'] ?? metadataMap['text/plain'];

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

          final int minNetworkLimit = _lightningLimits!.send.minSat.toInt();
          final int maxNetworkLimit = _lightningLimits!.send.maxSat.toInt();
          final int minSendableSat = widget.requestData.minSendable.toInt() ~/ 1000;
          final int maxSendableSat = widget.requestData.maxSendable.toInt() ~/ 1000;
          final int effectiveMinSat = min(
            max(minNetworkLimit, minSendableSat),
            maxNetworkLimit,
          );
          final int effectiveMaxSat = max(
            minNetworkLimit,
            min(maxNetworkLimit, maxSendableSat),
          );

          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.zero,
                      child: Center(child: LNURLMetadataImage(base64String: base64String)),
                    ),
                    if (_isFixedAmount) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: LnPaymentHeader(
                          payeeName: payeeName,
                          totalAmount: maxSendableSat + (_prepareResponse?.feesSat.toInt() ?? 0),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: LnUrlPaymentLimits(
                          limitsResponse: _lightningLimits,
                          minSendableSat: minSendableSat,
                          maxSendableSat: maxSendableSat,
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
                    ],
                    if (_prepareResponse != null && _isFixedAmount) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: LnPaymentAmount(amountSat: maxSendableSat),
                      ),
                    ],
                    if (_isFixedAmount) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: LnPaymentFee(
                          isCalculatingFees: _isCalculatingFees,
                          feesSat: errorMessage.isEmpty ? _prepareResponse?.feesSat.toInt() : null,
                        ),
                      ),
                    ],
                    if (metadataText != null && metadataText.isNotEmpty) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: LnPaymentDescription(
                          metadataText: metadataText,
                        ),
                      ),
                    ],
                    if (widget.requestData.commentAllowed > 0) ...<Widget>[
                      LnUrlPaymentComment(
                        enabled: _isFormEnabled,
                        descriptionController: _descriptionController,
                        maxCommentLength: widget.requestData.commentAllowed.toInt(),
                      ),
                    ],
                  ],
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
                  text: texts.ln_payment_action_retry,
                  onPressed: () {
                    _fetchLightningLimits();
                  },
                )
              : !_isFormEnabled || _isFixedAmount && errorMessage.isNotEmpty
                  ? SingleButtonBottomBar(
                      stickToBottom: true,
                      text: texts.ln_payment_action_close,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  : !_isFixedAmount
                      ? SingleButtonBottomBar(
                          stickToBottom: true,
                          text: texts.lnurl_payment_page_action_next,
                          onPressed: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              await _openConfirmationPage();
                            }
                          },
                        )
                      : _prepareResponse != null
                          ? SingleButtonBottomBar(
                              stickToBottom: true,
                              text: texts.ln_payment_action_send,
                              onPressed: () async {
                                Navigator.pop(context, _prepareResponse);
                              },
                            )
                          : const SizedBox.shrink(),
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

    if (!widget.isConfirmation && !_isFixedAmount && effectiveMinSat == effectiveMaxSat) {
      final int minNetworkLimit = _lightningLimits!.send.minSat.toInt();
      final int maxNetworkLimit = _lightningLimits!.send.maxSat.toInt();
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
          : texts.lnurl_payment_page_error_exceeds_limit(effectiveMaxSat);
    } else if (amountSat < effectiveMinSat) {
      final String effMinSendableFormatted = currencyState.bitcoinCurrency.format(effectiveMinSat);
      message = throwError
          ? '${texts.invoice_payment_validator_error_payment_below_invoice_limit(effMinSendableFormatted)}.'
          : texts.lnurl_payment_page_error_below_limit(effectiveMinSat);
    } else {
      message = PaymentValidator(
        validatePayment: _validateLnUrlPayment,
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

  void _validateLnUrlPayment(int amount, bool outgoing) {
    final AccountCubit accountCubit = context.read<AccountCubit>();
    final AccountState accountState = accountCubit.state;
    final int balance = accountState.walletInfo!.balanceSat.toInt();
    final LnUrlCubit lnUrlCubit = context.read<LnUrlCubit>();
    return lnUrlCubit.validateLnUrlPayment(BigInt.from(amount), outgoing, _lightningLimits!, balance);
  }

  Future<void> _openConfirmationPage() async {
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;
    final int amountSat = currencyState.bitcoinCurrency.parse(_amountController.text);
    final BigInt amountMsat = BigInt.from(amountSat * 1000);
    final LnUrlPayRequestData requestData = widget.requestData.copyWith(
      minSendable: amountMsat,
      maxSendable: amountMsat,
    );
    final PrepareLnUrlPayResponse? prepareResponse =
        await Navigator.of(context).push<PrepareLnUrlPayResponse?>(
      FadeInRoute<PrepareLnUrlPayResponse?>(
        builder: (_) => BlocProvider<PaymentLimitsCubit>(
          create: (BuildContext context) => PaymentLimitsCubit(ServiceInjector().breezSdkLiquid),
          child: LnUrlPaymentPage(
            isConfirmation: true,
            requestData: requestData,
            comment: _descriptionController.text,
          ),
        ),
      ),
    );
    if (prepareResponse == null || !context.mounted) {
      return Future<void>.value();
    }
    if (mounted) {
      Navigator.pop(context, prepareResponse);
    }
  }
}

extension LnUrlPayRequestDataCopyWith on LnUrlPayRequestData {
  LnUrlPayRequestData copyWith({
    BigInt? minSendable,
    BigInt? maxSendable,
  }) {
    return LnUrlPayRequestData(
      callback: callback,
      minSendable: minSendable ?? this.minSendable,
      maxSendable: maxSendable ?? this.maxSendable,
      metadataStr: metadataStr,
      commentAllowed: commentAllowed,
      domain: domain,
      allowsNostr: allowsNostr,
      nostrPubkey: nostrPubkey,
      lnAddress: lnAddress,
    );
  }
}
