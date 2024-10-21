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
import 'package:l_breez/widgets/warning_box.dart';

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
  String? _errorMessage;
  String validatorErrorMessage = "";
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
      await _handleLightningPaymentLimitsResponse(response);
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _handleLightningPaymentLimitsResponse(LightningPaymentLimitsResponse response) async {
    final minSendableSat = widget.requestData.minSendable.toInt() ~/ 1000;
    final maxSendableSat = widget.requestData.maxSendable.toInt() ~/ 1000;
    final effectiveMinSat = max(response.send.minSat.toInt(), minSendableSat);
    final effectiveMaxSat = min(response.send.maxSat.toInt(), maxSendableSat);

    _validateEffectiveLimits(effectiveMinSat: effectiveMinSat, effectiveMaxSat: effectiveMaxSat);

    await _updateFormFields(effectiveMaxSat: effectiveMaxSat);
    setState(() {
      _lightningLimits = response;
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
        final effMinWithdrawableFormatted = currencyState.bitcoinCurrency.format(
          effectiveMinSat,
          removeTrailingZeros: true,
        );
        final effMaxWithdrawableFormatted = currencyState.bitcoinCurrency.format(
          effectiveMaxSat,
          removeTrailingZeros: true,
        );
        throw Exception(
          "Payment amount($effMaxWithdrawableFormatted) is below minimum accepted amount of $effMinWithdrawableFormatted.",
        );
      }

      final networkLimit = currencyState.bitcoinCurrency.format(
        effectiveMinSat,
        includeDisplayName: true,
      );
      throw Exception(texts.invoice_payment_validator_error_payment_below_invoice_limit(networkLimit));
    }
  }

  Future<void> _updateFormFields({
    required int effectiveMaxSat,
  }) async {
    if (_isFixedAmount) {
      final currencyCubit = context.read<CurrencyCubit>();
      final currencyState = currencyCubit.state;

      _amountController.text = currencyState.bitcoinCurrency.format(
        effectiveMaxSat,
        includeDisplayName: false,
      );
      await _prepareLnUrlPayment(effectiveMaxSat);
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
        validatorErrorMessage = "";
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
        validatorErrorMessage = extractExceptionMessage(error, texts);
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

          if (_errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: WarningBox(
                  boxPadding: EdgeInsets.zero,
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                  ),
                ),
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
          final effectiveMinSat = max(_lightningLimits!.send.minSat.toInt(), minSendableSat);
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
                    if (_isFixedAmount && _prepareResponse != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: LnUrlPaymentHeader(
                          payeeName: payeeName,
                          totalAmount: effectiveMaxSat + _prepareResponse!.feesSat.toInt(),
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
                        validatorFn: (amount) => validatePayment(
                          amount: amount,
                          effectiveMinSat: effectiveMinSat,
                          effectiveMaxSat: effectiveMaxSat,
                        ),
                        onFieldSubmitted: (amount) async {
                          await _prepareLnUrlPayment(currencyState.bitcoinCurrency.parse(amount));
                        },
                        style: FieldTextStyle.textStyle,
                      ),
                    ],
                    if (!_isFixedAmount) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: LnUrlPaymentLimits(
                          effectiveMinSat: effectiveMinSat,
                          effectiveMaxSat: effectiveMaxSat,
                          onTap: (amountSat) async {
                            setState(() {
                              _amountController.text = currencyState.bitcoinCurrency.format(
                                amountSat,
                                includeDisplayName: false,
                              );
                            });
                            await _prepareLnUrlPayment(amountSat);
                          },
                        ),
                      ),
                    ],
                    if (_prepareResponse != null && _isFixedAmount) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: LnUrlPaymentAmount(amountSat: effectiveMaxSat),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: LnUrlPaymentFee(
                        isCalculatingFees: _isCalculatingFees,
                        feesSat: _prepareResponse?.feesSat.toInt(),
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
      bottomNavigationBar: _errorMessage != null
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
    required int amount,
    required int effectiveMinSat,
    required int effectiveMaxSat,
  }) {
    if (validatorErrorMessage.isNotEmpty) {
      return validatorErrorMessage;
    }
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
}
