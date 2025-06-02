import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/services/services.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:service_injector/service_injector.dart';

class LnOfferPaymentArguments {
  final LNOffer lnOffer;
  final String? bip353Address;

  LnOfferPaymentArguments({required this.lnOffer, required this.bip353Address});
}

class LnOfferPaymentPage extends StatefulWidget {
  final LnOfferPaymentArguments lnOfferPaymentArguments;
  final bool isConfirmation;
  final bool isDrain;
  final int? amountSat;
  final String? comment;

  static const String routeName = '/ln_offer_payment';
  static const PaymentMethod paymentMethod = PaymentMethod.bolt11Invoice;

  const LnOfferPaymentPage({
    required this.lnOfferPaymentArguments,
    this.isConfirmation = false,
    this.isDrain = false,
    this.amountSat,
    this.comment,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => LnOfferPaymentPageState();
}

class LnOfferPaymentPageState extends State<LnOfferPaymentPage> {
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
  bool _isCalculatingFees = false;
  String errorMessage = '';
  LightningPaymentLimitsResponse? _lightningLimits;

  PrepareSendResponse? _prepareResponse;

  bool _isDrain = false;

  @override
  void initState() {
    super.initState();
    _doneAction = KeyboardDoneAction(focusNodes: <FocusNode>[_amountFocusNode]);

    _isFixedAmount = widget.amountSat != null;
    _isDrain = widget.isDrain;
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
      String message = ExceptionHandler.extractMessage(error, texts);
      if (error is LnUrlPayError_ServiceConnectivity) {
        message = texts.lnurl_fetch_invoice_error_message(
          widget.lnOfferPaymentArguments.lnOffer.issuer ?? 'unknown issuer',
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
    final int amountSat = widget.amountSat ?? effectiveMinSat;
    _updateFormFields(amountSat: amountSat);
    final String? errorMessage = validatePayment(amountSat: amountSat, throwError: true);
    if (errorMessage == null && _isFixedAmount) {
      await _prepareSendPayment(amountSat);
      if (mounted && _isDrain) {
        final AccountCubit accountCubit = context.read<AccountCubit>();
        final AccountState accountState = accountCubit.state;
        final int balance = accountState.walletInfo!.balanceSat.toInt();
        final int feesSat = _prepareResponse?.feesSat?.toInt() ?? 0;

        _updateFormFields(amountSat: balance - feesSat);
      }
    }
  }

  void _updateFormFields({required int amountSat}) {
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;

    setState(() {
      _amountController.text = currencyState.bitcoinCurrency.format(amountSat, includeDisplayName: false);
      _descriptionController.text = widget.comment ?? '';
    });
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

      final String destination =
          widget.lnOfferPaymentArguments.bip353Address ?? widget.lnOfferPaymentArguments.lnOffer.offer;

      final PayAmount payAmount = _isDrain
          ? const PayAmount_Drain()
          : PayAmount_Bitcoin(receiverAmountSat: BigInt.from(amountSat));

      final PrepareSendRequest req = PrepareSendRequest(destination: destination, amount: payAmount);

      final PrepareSendResponse response = await paymentsCubit.prepareSendPayment(req: req);
      setState(() {
        _prepareResponse = response;
      });
    } catch (error) {
      setState(() {
        _prepareResponse = null;
        errorMessage = ExceptionHandler.extractMessage(error, texts);
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

    final String? issuer = widget.lnOfferPaymentArguments.lnOffer.issuer;
    final bool hasIssuer = issuer != null && issuer.isNotEmpty;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(
          hasIssuer ? texts.lnurl_fetch_invoice_pay_to_payee(issuer) : texts.ln_payment_send_payment_title,
        ),
      ),
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

          final int amountSat = currencyState.bitcoinCurrency.parse(_amountController.text);

          final bool offerHasDescription =
              widget.lnOfferPaymentArguments.lnOffer.description != null &&
              widget.lnOfferPaymentArguments.lnOffer.description!.isNotEmpty;

          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 40),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (_isFixedAmount) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: LnPaymentHeader(
                          payeeName: issuer ?? '',
                          totalAmount: amountSat,
                          errorMessage: errorMessage,
                        ),
                      ),
                    ],
                    Container(
                      decoration: ShapeDecoration(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        color: themeData.customData.surfaceBgColor,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      child: Column(
                        children:
                            <Widget>[
                                if (!_isFixedAmount && offerHasDescription) ...<Widget>[
                                  LnPaymentDescription(
                                    metadataText: widget.lnOfferPaymentArguments.lnOffer.description!,
                                  ),
                                ],
                                if (!_isFixedAmount) ...<Widget>[
                                  Column(
                                    children: <Widget>[
                                      const SizedBox(height: 8.0),
                                      AmountFormField(
                                        context: context,
                                        texts: texts,
                                        bitcoinCurrency: currencyState.bitcoinCurrency,
                                        focusNode: _amountFocusNode,
                                        autofocus: _isFormEnabled && errorMessage.isEmpty,
                                        enabled: _isFormEnabled && !_isDrain,
                                        enableInteractiveSelection: _isFormEnabled,
                                        controller: _amountController,
                                        validatorFn: (int amountSat) => validatePayment(amountSat: amountSat),
                                        errorStyle: FieldTextStyle.labelStyle.copyWith(
                                          fontSize: 18.0,
                                          color: themeData.colorScheme.error,
                                        ),
                                        returnFN: (String amountStr) async {
                                          if (amountStr.isNotEmpty) {
                                            final int amountSat = currencyState.bitcoinCurrency.parse(
                                              amountStr,
                                            );
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
                                      ),
                                      if (!_isFormEnabled ||
                                          _isFixedAmount && errorMessage.isNotEmpty) ...<Widget>[
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
                                    ],
                                  ),
                                  BlocBuilder<AccountCubit, AccountState>(
                                    builder: (BuildContext context, AccountState accountState) {
                                      return ListTile(
                                        dense: true,
                                        minTileHeight: 0,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(
                                          texts.withdraw_funds_use_all_funds,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18.0,
                                            height: 1.208,
                                            fontWeight: FontWeight.w400,
                                            fontFamily: 'IBMPlexSans',
                                          ),
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            '${texts.available_balance_label} ${currencyState.bitcoinCurrency.format(accountState.walletInfo!.balanceSat.toInt())}',
                                            style: const TextStyle(
                                              color: Color.fromRGBO(182, 188, 193, 1),
                                              fontSize: 16.0,
                                              height: 1.182,
                                              fontWeight: FontWeight.w400,
                                              fontFamily: 'IBMPlexSans',
                                            ),
                                          ),
                                        ),
                                        trailing: Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Switch(
                                            value: _isDrain,
                                            activeColor: Colors.white,
                                            activeTrackColor: themeData.primaryColor,
                                            onChanged: (bool value) async {
                                              setState(() {
                                                setState(() {
                                                  _isDrain = value;
                                                });
                                                final String formattedAmount = currencyState.bitcoinCurrency
                                                    .format(
                                                      value
                                                          ? accountState.walletInfo!.balanceSat.toInt()
                                                          : effectiveMinSat,
                                                      includeDisplayName: false,
                                                      userInput: true,
                                                    )
                                                    .formatBySatAmountFormFieldFormatter();
                                                setState(() {
                                                  _amountController.text = formattedAmount;
                                                });
                                                _formKey.currentState?.validate();
                                              });
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                if (_isFixedAmount) ...<Widget>[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: LnPaymentAmount(
                                      amountSat: amountSat,
                                      hasError: !_isFormEnabled || errorMessage.isNotEmpty,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: LnPaymentFee(
                                      isCalculatingFees: _isCalculatingFees,
                                      feesSat: errorMessage.isEmpty
                                          ? _prepareResponse?.feesSat?.toInt()
                                          : null,
                                    ),
                                  ),
                                  if (offerHasDescription) ...<Widget>[
                                    Padding(
                                      padding: _prepareResponse == null
                                          ? EdgeInsets.zero
                                          : const EdgeInsets.only(top: 8.0),
                                      child: LnPaymentDescription(
                                        metadataText: widget.lnOfferPaymentArguments.lnOffer.description!,
                                      ),
                                    ),
                                  ],
                                ],
                                LnUrlPaymentComment(
                                  isConfirmation: widget.isConfirmation,
                                  enabled: _isFormEnabled,
                                  descriptionController: _descriptionController,
                                  descriptionFocusNode: _descriptionFocusNode,
                                  maxCommentLength: 255,
                                ),
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
                final String comment = widget.comment ?? _descriptionController.text;
                final SendPaymentRequest sendPaymentRequest = SendPaymentRequest(
                  prepareResponse: _prepareResponse!,
                  payerNote: comment,
                );
                Navigator.pop(context, sendPaymentRequest);
              },
            )
          : const SizedBox.shrink(),
    );
  }

  String? validatePayment({required int amountSat, bool throwError = false}) {
    final BreezTranslations texts = context.texts();
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    final CurrencyState currencyState = currencyCubit.state;

    String? message;
    if (_lightningLimits == null) {
      message = texts.payment_limits_fetch_error_message;
    }

    final int effectiveMaxSat = _lightningLimits!.send.maxSat.toInt();

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
    } else if (amountSat > effectiveMaxSat) {
      final String networkLimit = '(${currencyState.bitcoinCurrency.format(effectiveMaxSat)})';
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
    final LnUrlService lnUrlService = Provider.of<LnUrlService>(context, listen: false);
    return lnUrlService.validateLnUrlPayment(
      amount: BigInt.from(amount),
      outgoing: outgoing,
      lightningLimits: _lightningLimits!,
      balance: balance,
    );
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
            isConfirmation: true,
            isDrain: _isDrain,
            amountSat: amountSat,
            lnOfferPaymentArguments: widget.lnOfferPaymentArguments,
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
    final Amount? lnOfferMinAmount = widget.lnOfferPaymentArguments.lnOffer.minAmount;
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
