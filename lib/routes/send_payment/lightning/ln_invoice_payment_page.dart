import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/services/lnurl_service.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';
import 'package:provider/provider.dart';

class LnPaymentPage extends StatefulWidget {
  final LNInvoice lnInvoice;

  static const String routeName = '/ln_invoice_payment';
  static const PaymentMethod paymentMethod = PaymentMethod.bolt11Invoice;

  const LnPaymentPage({required this.lnInvoice, super.key});

  @override
  State<StatefulWidget> createState() => LnPaymentPageState();
}

class LnPaymentPageState extends State<LnPaymentPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  bool _isCalculatingFees = false;
  String errorMessage = '';
  LightningPaymentLimitsResponse? _lightningLimits;

  int? amountSat;
  PrepareSendResponse? _prepareResponse;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final BigInt? amountMsat = widget.lnInvoice.amountMsat;
      if ((amountMsat == null || amountMsat == BigInt.zero) && context.mounted) {
        final BreezTranslations texts = context.texts();
        Navigator.pop(context);
        showFlushbar(
          context,
          message: texts.payment_request_zero_amount_not_supported,
        );
      }

      setState(() {
        amountSat = amountMsat!.toInt() ~/ 1000;
      });
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
    final String? errorMessage = validatePayment(
      amountSat: amountSat!,
      throwError: true,
    );
    if (errorMessage == null) {
      await _prepareSendPayment(amountSat!);
    }
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

      final PayAmount payAmount = PayAmount_Bitcoin(
        receiverAmountSat: BigInt.from(amountSat),
      );

      final PrepareSendRequest req = PrepareSendRequest(
        destination: widget.lnInvoice.bolt11,
        amount: payAmount,
      );

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
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.ln_payment_send_payment_title),
      ),
      body: BlocBuilder<CurrencyCubit, CurrencyState>(
        builder: (BuildContext context, CurrencyState currencyState) {
          if (_isLoading) {
            return const CenteredLoader();
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 40),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: LnPaymentHeader(
                      payeeName: '',
                      totalAmount: amountSat! + (_prepareResponse?.feesSat?.toInt() ?? 0),
                      errorMessage: errorMessage,
                    ),
                  ),
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
                      vertical: 16,
                      horizontal: 24,
                    ),
                    child: Column(
                      children: <Widget>[
                        LnPaymentAmount(
                          amountSat: amountSat!,
                          hasError: errorMessage.isNotEmpty,
                        ),
                        if (_prepareResponse != null && _prepareResponse!.feesSat?.toInt() != 0) ...<Widget>[
                          LnPaymentFee(
                            isCalculatingFees: _isCalculatingFees,
                            feesSat: errorMessage.isEmpty ? _prepareResponse?.feesSat?.toInt() : null,
                          ),
                        ],
                        if (widget.lnInvoice.description != null &&
                            widget.lnInvoice.description!.isNotEmpty) ...<Widget>[
                          LnPaymentDescription(
                            metadataText: widget.lnInvoice.description!,
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
              : SingleButtonBottomBar(
                  stickToBottom: true,
                  text: texts.ln_payment_action_send,
                  enabled: _prepareResponse != null && errorMessage.isEmpty,
                  onPressed: () async {
                    Navigator.pop(context, _prepareResponse);
                  },
                ),
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
    final int effectiveMinSat = _lightningLimits!.send.minSat.toInt();
    final int effectiveMaxSat = _lightningLimits!.send.maxSat.toInt();
    if (amountSat > effectiveMaxSat) {
      final String networkLimit = '(${currencyState.bitcoinCurrency.format(
        effectiveMaxSat,
      )})';
      message = throwError
          ? texts.valid_payment_error_exceeds_the_limit(networkLimit)
          : '${texts.lnurl_payment_page_error_exceeds_limit(effectiveMaxSat)} ${currencyState.bitcoinCurrency.displayName}';
    } else if (amountSat < effectiveMinSat) {
      final String effMinSendableFormatted = currencyState.bitcoinCurrency.format(effectiveMinSat);
      message = throwError
          ? '${texts.invoice_payment_validator_error_payment_below_invoice_limit(effMinSendableFormatted)}.'
          : '${texts.lnurl_payment_page_error_below_limit(effectiveMinSat)} ${currencyState.bitcoinCurrency.displayName}';
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
}
