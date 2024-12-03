import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/theme/src/theme.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/utils/payment_validator.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/widgets.dart';
import 'package:service_injector/service_injector.dart';

class LnOfferPaymentPage extends StatefulWidget {
  final LNOffer lnOffer;
  final int? amountSat;
  final String? comment;

  static const String routeName = '/ln_offer_payment';
  static const PaymentMethod paymentMethod = PaymentMethod.lightning;

  const LnOfferPaymentPage({required this.lnOffer, this.amountSat, this.comment, super.key});

  @override
  State<StatefulWidget> createState() => LnOfferPaymentPageState();
}

class LnOfferPaymentPageState extends State<LnOfferPaymentPage> {
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

  PrepareSendResponse? _prepareResponse;

  @override
  void initState() {
    super.initState();
    _doneAction = KeyboardDoneAction(focusNodes: <FocusNode>[_amountFocusNode]);

    _isFixedAmount = widget.amountSat != null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _updateFormFields();
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
          widget.lnOffer.issuer ?? 'unknown issuer',
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
    if (_isFixedAmount) {
      final String? errorMessage = validatePayment(
        amountSat: widget.amountSat!,
        throwError: true,
      );
      if (errorMessage == null) {
        await _prepareSendPayment(widget.amountSat!);
      }
    }
  }

  void _updateFormFields() {
    _descriptionController.text = widget.comment ?? '';
  }

  Future<void> _prepareSendPayment(int amountSat) async {
    final BreezTranslations texts = context.texts();
    final PaymentsCubit paymentsCubit = context.read<PaymentsCubit>();
    try {
      setState(() {
        _isCalculatingFees = true;
        _prepareResponse = null;
        errorMessage = '';
      });

      final PrepareSendResponse response = await paymentsCubit.prepareSendPayment(
        destination: widget.lnOffer.offer,
        amountSat: BigInt.from(amountSat),
      );
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
        title: Text(texts.lnurl_fetch_invoice_pay_to_payee(widget.lnOffer.issuer ?? 'unknown host')),
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

          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (_isFixedAmount) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: LnPaymentHeader(
                          payeeName: widget.lnOffer.issuer ?? 'unknown host',
                          totalAmount: widget.amountSat! + (_prepareResponse?.feesSat.toInt() ?? 0),
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
                          minSendableSat: effectiveMinSat,
                          maxSendableSat: _lightningLimits!.send.maxSat.toInt(),
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
                        child: LnPaymentAmount(amountSat: widget.amountSat!),
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
                    if (widget.lnOffer.description != null &&
                        widget.lnOffer.description!.isNotEmpty) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: LnPaymentDescription(
                          metadataText: widget.lnOffer.description!,
                        ),
                      ),
                    ],
                    if (widget.comment?.isNotEmpty ?? false) ...<Widget>[
                      LnUrlPaymentComment(
                        enabled: _isFormEnabled,
                        descriptionController: _descriptionController,
                        maxCommentLength: 255,
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
    bool throwError = false,
  }) {
    final BreezTranslations texts = context.texts();
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;

    String? message;
    if (_lightningLimits == null) {
      message = texts.payment_limits_fetch_error_message;
    }

    final int effectiveMaxSat = _lightningLimits!.send.maxSat.toInt();

    if (!_isFixedAmount && effectiveMinSat == effectiveMaxSat) {
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

    final PrepareSendResponse? prepareResponse = await Navigator.of(context).push<PrepareSendResponse?>(
      FadeInRoute<PrepareSendResponse?>(
        builder: (_) => BlocProvider<PaymentLimitsCubit>(
          create: (BuildContext context) => PaymentLimitsCubit(ServiceInjector().breezSdkLiquid),
          child: LnOfferPaymentPage(
            amountSat: amountSat,
            lnOffer: widget.lnOffer,
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

  int get effectiveMinSat {
    final int minNetworkLimitSat = _lightningLimits!.send.minSat.toInt();
    int minOfferAmountSat = 0;
    final Amount? lnOfferMinAmount = widget.lnOffer.minAmount;
    if (lnOfferMinAmount != null) {
      if (lnOfferMinAmount is Amount_Currency) {
        // TODO(erdemyerebasmaz): Handle Amount_Currency later.
        final BigInt minOfferAmountMsat = lnOfferMinAmount.fractionalAmount;
        minOfferAmountSat = minOfferAmountMsat.toInt() ~/ 1000;
        throw 'Amount_Currency is not supported yet';
      } else if (lnOfferMinAmount is Amount_Bitcoin) {
        final BigInt minOfferAmountMsat = lnOfferMinAmount.amountMsat;
        minOfferAmountSat = minOfferAmountMsat.toInt() ~/ 1000;
      }
    }

    return max(minNetworkLimitSat, minOfferAmountSat);
  }
}
