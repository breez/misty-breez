import 'dart:convert';
import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_metadata.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/always_disabled_focus_node.dart';
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
      if (_isFixedAmount) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
      setState(() {
        _prepareResponse = null;
        validatorErrorMessage = extractExceptionMessage(error, texts);
        _loading = false;
      });
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

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.lnurl_fetch_invoice_pay_to_payee(widget.requestData.domain)),
      ),
      body: BlocBuilder<CurrencyCubit, CurrencyState>(builder: (context, currencyState) {
        final themeData = Theme.of(context);
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
        String payeeName = metadataMap["text/identifier"] ?? widget.requestData.domain;
        String? metadataText = metadataMap['text/long-desc'] ?? metadataMap['text/plain'];

        final minSendableSat = widget.requestData.minSendable.toInt() ~/ 1000;
        final maxSendableSat = widget.requestData.maxSendable.toInt() ~/ 1000;
        final effectiveMinSat = max(_lightningLimits!.send.minSat.toInt(), minSendableSat);
        final effectiveMaxSat = min(_lightningLimits!.send.maxSat.toInt(), maxSendableSat);
        final effMinSendableFormatted = currencyState.bitcoinCurrency.format(effectiveMinSat);
        final effMaxSendableFormatted = currencyState.bitcoinCurrency.format(effectiveMaxSat);

        return Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
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
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            payeeName,
                            style: Theme.of(context).primaryTextTheme.headlineMedium!.copyWith(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            payeeName.isEmpty
                                ? texts.payment_request_dialog_requested
                                : texts.payment_request_dialog_requesting,
                            style: themeData.primaryTextTheme.displaySmall!.copyWith(fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          RichText(
                            text: TextSpan(
                              style: balanceAmountTextStyle.copyWith(
                                color: themeData.colorScheme.onSecondary,
                              ),
                              text: currencyState.bitcoinCurrency.format(
                                effectiveMaxSat + _prepareResponse!.feesSat.toInt(),
                                removeTrailingZeros: true,
                                includeDisplayName: false,
                              ),
                              children: [
                                TextSpan(
                                  text: " ${currencyState.bitcoinCurrency.displayName}",
                                  style: balanceCurrencyTextStyle.copyWith(
                                    color: themeData.colorScheme.onSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (!_isFixedAmount) ...[
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
                    onFieldSubmitted: (amount) async {
                      await _prepareLnUrlPayment(currencyState.bitcoinCurrency.parse(amount));
                    },
                    style: FieldTextStyle.textStyle,
                  ),
                ],
                if (!_isFixedAmount) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: RichText(
                      text: TextSpan(
                        style: FieldTextStyle.labelStyle,
                        children: <TextSpan>[
                          TextSpan(
                            text: texts.lnurl_fetch_invoice_min(effMinSendableFormatted),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                await _pasteAmount(currencyState, effectiveMinSat);
                              },
                          ),
                          TextSpan(
                            text: texts.lnurl_fetch_invoice_and(effMaxSendableFormatted),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                await _pasteAmount(currencyState, effectiveMaxSat);
                              },
                          )
                        ],
                      ),
                    ),
                  ),
                ],
                if (_prepareResponse != null && _isFixedAmount) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: AutoSizeText(
                            texts.send_on_chain_amount,
                            style: themeData.primaryTextTheme.headlineMedium,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: AutoSizeText(
                              currencyState.bitcoinCurrency.format(effectiveMaxSat),
                              style: TextStyle(color: themeData.colorScheme.error),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: AutoSizeText(
                          "${texts.csv_exporter_fee}:",
                          style: themeData.primaryTextTheme.headlineMedium,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: (_isCalculatingFees)
                              ? Center(
                                  child: SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      color: themeData.primaryColor.withOpacity(0.5),
                                    ),
                                  ),
                                )
                              : (_prepareResponse != null)
                                  ? AutoSizeText(
                                      texts.payment_details_dialog_amount_positive(
                                        currencyState.bitcoinCurrency.format(
                                          _prepareResponse!.feesSat.toInt(),
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: themeData.colorScheme.error.withOpacity(0.4),
                                      ),
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                    )
                                  : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (metadataText != null && metadataText.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          texts.utils_print_pdf_header_description,
                          style: themeData.primaryTextTheme.headlineMedium,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: LNURLMetadataText(metadataText: metadataText),
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.requestData.commentAllowed > 0) ...[
                  TextFormField(
                    controller: _descriptionController,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.done,
                    maxLines: null,
                    maxLength: widget.requestData.commentAllowed.toInt(),
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    decoration: InputDecoration(
                      labelText: "${texts.lnurl_payment_page_comment}:",
                      labelStyle: themeData.primaryTextTheme.headlineMedium,
                    ),
                    style: themeData.paymentItemSubtitleTextStyle,
                  )
                ],
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: _loading || _isCalculatingFees || _prepareResponse == null
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
                  text: texts.lnurl_payment_page_action_pay,
                  onPressed: () async {
                    Navigator.pop(context, _prepareResponse);
                  },
                ),
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

  Future<void> _pasteAmount(CurrencyState currencyState, int amountSat) async {
    setState(() {
      _amountController.text = currencyState.bitcoinCurrency.format(
        amountSat,
        includeDisplayName: false,
      );
    });
    await _prepareLnUrlPayment(amountSat);
  }
}
