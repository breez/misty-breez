import 'dart:convert';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/lnurl/payment/widgets/widgets.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_metadata.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/utils/payment_validator.dart';
import 'package:l_breez/widgets/amount_form_field/amount_form_field.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/keyboard_done_action.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/route.dart';
import 'package:l_breez/widgets/scrollable_error_message_widget.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';
import 'package:service_injector/service_injector.dart';

class LnUrlPaymentPage extends StatefulWidget {
  final LnUrlPayRequestData requestData;
  final String? comment;

  static const routeName = "/lnurl_payment";
  static const paymentMethod = PaymentMethod.lightning;

  const LnUrlPaymentPage({super.key, required this.requestData, this.comment});

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
  bool _isFormEnabled = true;
  bool _isCalculatingFees = false;
  String errorMessage = "";
  LightningPaymentLimitsResponse? _lightningLimits;

  PrepareLnUrlPayResponse? _prepareResponse;

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
      setState(() {
        _lightningLimits = response;
      });
      await _handleLightningPaymentLimitsResponse();
    } catch (error) {
      final texts = getSystemAppLocalizations();
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
        _loading = false;
      });
    }
  }

  Future<void> _handleLightningPaymentLimitsResponse() async {
    final minNetworkLimit = _lightningLimits!.send.minSat.toInt();
    final maxNetworkLimit = _lightningLimits!.send.maxSat.toInt();
    final minSendableSat = widget.requestData.minSendable.toInt() ~/ 1000;
    final maxSendableSat = widget.requestData.maxSendable.toInt() ~/ 1000;
    final effectiveMinSat = min(
      max(minNetworkLimit, minSendableSat),
      maxNetworkLimit,
    );
    final rawMaxSat = min(maxNetworkLimit, maxSendableSat);
    _updateFormFields(amountSat: minSendableSat);
    final errorMessage = validatePayment(
      amountSat: _isFixedAmount ? minSendableSat : effectiveMinSat,
      effectiveMinSat: effectiveMinSat,
      effectiveMaxSat: rawMaxSat,
      throwError: true,
    );
    if (errorMessage == null && _isFixedAmount) {
      await _prepareLnUrlPayment(rawMaxSat);
    }
  }

  void _updateFormFields({
    required int amountSat,
  }) {
    if (!_isFixedAmount) {
      final currencyCubit = context.read<CurrencyCubit>();
      final currencyState = currencyCubit.state;

      _amountController.text = currencyState.bitcoinCurrency.format(
        amountSat,
        includeDisplayName: false,
      );
    }
    _descriptionController.text = widget.comment ?? "";
  }

  Future<void> _prepareLnUrlPayment(int amountSat) async {
    final texts = context.texts();
    final lnUrlCubit = context.read<LnUrlCubit>();
    try {
      setState(() {
        _isCalculatingFees = true;
        _prepareResponse = null;
        errorMessage = "";
      });
      final req = PrepareLnUrlPayRequest(
        data: widget.requestData,
        amountMsat: BigInt.from(amountSat * 1000),
      );
      final response = await lnUrlCubit.prepareLnurlPay(req: req);
      setState(() {
        _prepareResponse = response;
      });
    } catch (error) {
      setState(() {
        _prepareResponse = null;
        errorMessage = extractExceptionMessage(error, texts);
        _loading = false;
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
    final texts = context.texts();
    final themeData = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.lnurl_fetch_invoice_pay_to_payee(widget.requestData.domain)),
      ),
      body: BlocBuilder<CurrencyCubit, CurrencyState>(
        builder: (context, currencyState) {
          if (_loading) {
            return Center(
              child: Loader(
                color: themeData.primaryColor.withOpacity(0.5),
              ),
            );
          }

          final metadataMap = {
            for (var v in json.decode(widget.requestData.metadataStr)) v[0] as String: v[1],
          };
          String? base64String = metadataMap['image/png;base64'] ?? metadataMap['image/jpeg;base64'];
          String payeeName = metadataMap["text/identifier"] ?? widget.requestData.domain;
          String? metadataText = metadataMap['text/long-desc'] ?? metadataMap['text/plain'];

          if (_lightningLimits == null) {
            if (errorMessage.isEmpty) {
              return Center(
                child: Loader(
                  color: themeData.primaryColor.withOpacity(0.5),
                ),
              );
            }
            return ScrollableErrorMessageWidget(
              title: "Failed to retrieve payment limits:",
              message: texts.reverse_swap_upstream_generic_error_message(errorMessage),
            );
          }

          final minNetworkLimit = _lightningLimits!.send.minSat.toInt();
          final maxNetworkLimit = _lightningLimits!.send.maxSat.toInt();
          final minSendableSat = widget.requestData.minSendable.toInt() ~/ 1000;
          final maxSendableSat = widget.requestData.maxSendable.toInt() ~/ 1000;
          final effectiveMinSat = min(
            max(minNetworkLimit, minSendableSat),
            maxNetworkLimit,
          );
          final effectiveMaxSat = max(
            minNetworkLimit,
            min(maxNetworkLimit, maxSendableSat),
          );

          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.zero,
                      child: Center(child: LNURLMetadataImage(base64String: base64String)),
                    ),
                    if (_isFixedAmount) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: LnUrlPaymentHeader(
                          payeeName: payeeName,
                          totalAmount: maxSendableSat + (_prepareResponse?.feesSat.toInt() ?? 0),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: LnUrlPaymentLimits(
                          limitsResponse: _lightningLimits,
                          minSendableSat: minSendableSat,
                          maxSendableSat: maxSendableSat,
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
                      if (errorMessage.isNotEmpty) ...[
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
                    if (_prepareResponse != null && _isFixedAmount) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: LnUrlPaymentAmount(amountSat: maxSendableSat),
                      ),
                    ],
                    if (_isFixedAmount) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: LnUrlPaymentFee(
                          isCalculatingFees: _isCalculatingFees,
                          feesSat: errorMessage.isEmpty ? _prepareResponse?.feesSat.toInt() : null,
                        ),
                      ),
                    ],
                    if (metadataText != null && metadataText.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: LnUrlPaymentDescription(
                          metadataText: metadataText,
                        ),
                      ),
                    ],
                    if (widget.requestData.commentAllowed > 0) ...[
                      LnUrlPaymentComment(
                        enabled: _isFormEnabled,
                        descriptionController: _descriptionController,
                        maxCommentLength: widget.requestData.commentAllowed.toInt(),
                      )
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: errorMessage.isNotEmpty
          ? SingleButtonBottomBar(
              stickToBottom: true,
              text: texts.qr_code_dialog_action_close,
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          : !_isFixedAmount
              ? SingleButtonBottomBar(
                  stickToBottom: true,
                  text: texts.lnurl_fetch_invoice_action_continue,
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      final currencyCubit = context.read<CurrencyCubit>();
                      final currencyState = currencyCubit.state;
                      final amountSat = currencyState.bitcoinCurrency.parse(_amountController.text);
                      final amountMsat = BigInt.from(amountSat * 1000);
                      final requestData = widget.requestData.copyWith(
                        minSendable: amountMsat,
                        maxSendable: amountMsat,
                      );
                      PrepareLnUrlPayResponse? prepareResponse =
                          await Navigator.of(context).push<PrepareLnUrlPayResponse?>(
                        FadeInRoute<PrepareLnUrlPayResponse?>(
                          builder: (_) => BlocProvider(
                            create: (BuildContext context) => PaymentLimitsCubit(ServiceInjector().liquidSDK),
                            child: LnUrlPaymentPage(
                              requestData: requestData,
                              comment: _descriptionController.text,
                            ),
                          ),
                        ),
                      );
                      if (prepareResponse == null || !context.mounted) {
                        return Future.value();
                      }
                      Navigator.pop(context, prepareResponse);
                    }
                  },
                )
              : _prepareResponse != null
                  ? SingleButtonBottomBar(
                      stickToBottom: true,
                      text: texts.lnurl_payment_page_action_pay,
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
    bool throwError = false,
  }) {
    final texts = context.texts();
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;

    String? message;
    if (_lightningLimits == null) {
      message = "Failed to retrieve network payment limits. Please try again later.";
    }

    if (_isFixedAmount && effectiveMinSat == effectiveMaxSat) {
      final minNetworkLimit = _lightningLimits!.send.minSat.toInt();
      final maxNetworkLimit = _lightningLimits!.send.maxSat.toInt();
      final minNetworkLimitFormatted = currencyState.bitcoinCurrency.format(minNetworkLimit);
      final maxNetworkLimitFormatted = currencyState.bitcoinCurrency.format(maxNetworkLimit);
      message =
          "Payment amount is outside the allowed limits, which range from $minNetworkLimitFormatted to $maxNetworkLimitFormatted";
    } else if (effectiveMaxSat < effectiveMinSat) {
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
          : texts.lnurl_payment_page_error_exceeds_limit(effectiveMaxSat);
    } else if (amountSat < effectiveMinSat) {
      final effMinSendableFormatted = currencyState.bitcoinCurrency.format(effectiveMinSat);
      message = throwError
          ? "${texts.invoice_payment_validator_error_payment_below_invoice_limit(effMinSendableFormatted)}."
          : texts.lnurl_payment_page_error_below_limit(effectiveMinSat);
    } else {
      message = PaymentValidator(
        validatePayment: _validateLnUrlPayment,
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

  void _validateLnUrlPayment(int amount, bool outgoing) {
    final accountCubit = context.read<AccountCubit>();
    final accountState = accountCubit.state;
    final balance = accountState.walletInfo!.balanceSat.toInt();
    final lnUrlCubit = context.read<LnUrlCubit>();
    return lnUrlCubit.validateLnUrlPayment(BigInt.from(amount), outgoing, _lightningLimits!, balance);
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
