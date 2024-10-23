import 'dart:convert';
import 'dart:math';

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
import 'package:l_breez/widgets/single_button_bottom_bar.dart';

class LnUrlPaymentPage extends StatefulWidget {
  final LnUrlPayRequestData requestData;

  static const routeName = "/lnurl_payment";
  static const paymentMethod = PaymentMethod.lightning;

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
      setState(() {
        errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _handleLightningPaymentLimitsResponse() async {
    final minSendableSat = widget.requestData.minSendable.toInt() ~/ 1000;
    final maxSendableSat = widget.requestData.maxSendable.toInt() ~/ 1000;
    final effectiveMinSat = min(
      max(_lightningLimits!.send.minSat.toInt(), minSendableSat),
      _lightningLimits!.send.maxSat.toInt(),
    );
    final effectiveMaxSat = min(_lightningLimits!.send.maxSat.toInt(), maxSendableSat);
    final errorMessage = validatePayment(
      amountSat: minSendableSat,
      effectiveMinSat: effectiveMinSat,
      effectiveMaxSat: effectiveMaxSat,
      throwError: true,
    );
    if (errorMessage == null) {
      await _updateFormFields(amountSat: effectiveMaxSat);
    }
  }

  Future<void> _updateFormFields({
    required int amountSat,
  }) async {
    if (_isFixedAmount) {
      final currencyCubit = context.read<CurrencyCubit>();
      final currencyState = currencyCubit.state;

      _amountController.text = currencyState.bitcoinCurrency.format(
        amountSat,
        includeDisplayName: false,
      );
      await _prepareLnUrlPayment(amountSat);
    } else if (_amountFocusNode.canRequestFocus) {
      _amountFocusNode.requestFocus();
    }
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

          final minSendableSat = widget.requestData.minSendable.toInt() ~/ 1000;
          final maxSendableSat = widget.requestData.maxSendable.toInt() ~/ 1000;
          final effectiveMinSat = min(
            max(_lightningLimits!.send.minSat.toInt(), minSendableSat),
            _lightningLimits!.send.maxSat.toInt(),
          );
          final effectiveMaxSat = min(_lightningLimits!.send.maxSat.toInt(), maxSendableSat);

          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (base64String != null && base64String.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Center(child: LNURLMetadataImage(base64String: base64String)),
                      ),
                    ],
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
                        autofocus: true,
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
                            if (_formKey.currentState?.validate() ?? false) {
                              await _prepareLnUrlPayment(amountSat);
                            }
                          }
                        },
                        onFieldSubmitted: (amountStr) async {
                          if (amountStr.isNotEmpty) {
                            final amountSat = currencyState.bitcoinCurrency.parse(amountStr);
                            if (_formKey.currentState?.validate() ?? false) {
                              await _prepareLnUrlPayment(amountSat);
                            }
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
                            if (_formKey.currentState?.validate() ?? false) {
                              await _prepareLnUrlPayment(amountSat);
                            }
                          },
                        ),
                      ),
                    ],
                    if (_prepareResponse != null && _isFixedAmount) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: LnUrlPaymentAmount(amountSat: maxSendableSat),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: LnUrlPaymentFee(
                        isCalculatingFees: _isCalculatingFees,
                        feesSat: errorMessage.isEmpty ? _prepareResponse?.feesSat.toInt() : null,
                      ),
                    ),
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

    if (amountSat > effectiveMaxSat) {
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
    final balance = accountState.balance;
    final lnUrlCubit = context.read<LnUrlCubit>();
    return lnUrlCubit.validateLnUrlPayment(BigInt.from(amount), outgoing, _lightningLimits!, balance);
  }
}
