import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/lnurl/payment/widgets/widgets.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/utils/payment_validator.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/flushbar.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';

class LnPaymentPage extends StatefulWidget {
  final LNInvoice lnInvoice;

  static const routeName = "/ln_invoice_payment";
  static const paymentMethod = PaymentMethod.lightning;

  const LnPaymentPage({super.key, required this.lnInvoice});

  @override
  State<StatefulWidget> createState() => LnPaymentPageState();
}

class LnPaymentPageState extends State<LnPaymentPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = true;
  bool _isCalculatingFees = false;
  String errorMessage = "";
  LightningPaymentLimitsResponse? _lightningLimits;

  int? amountSat;
  PrepareSendResponse? _prepareResponse;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final amountMsat = widget.lnInvoice.amountMsat;
      if ((amountMsat == null || amountMsat == BigInt.zero) && context.mounted) {
        final texts = context.texts();
        Navigator.pop(context);
        showFlushbar(context, message: texts.payment_request_zero_amount_not_supported);
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
      errorMessage = "";
    });
    final paymentLimitsCubit = context.read<PaymentLimitsCubit>();
    try {
      final response = await paymentLimitsCubit.fetchLightningLimits();
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
    final errorMessage = validatePayment(
      amountSat: amountSat!,
      throwError: true,
    );
    if (errorMessage == null) {
      await _prepareSendPayment(amountSat!);
    }
  }

  Future<void> _prepareSendPayment(int amountSat) async {
    final texts = context.texts();
    final paymentsCubit = context.read<PaymentsCubit>();
    try {
      setState(() {
        _isCalculatingFees = true;
        _prepareResponse = null;
        errorMessage = "";
      });

      final response = await paymentsCubit.prepareSendPayment(
        destination: widget.lnInvoice.bolt11,
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
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.ln_payment_send_payment_title),
      ),
      body: BlocBuilder<CurrencyCubit, CurrencyState>(
        builder: (context, currencyState) {
          if (_isLoading) {
            return Center(
              child: Loader(
                color: themeData.primaryColor.withOpacity(0.5),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: LnPaymentHeader(
                        payeeName: "",
                        totalAmount: amountSat! + (_prepareResponse?.feesSat.toInt() ?? 0),
                        errorMessage: errorMessage,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: LnPaymentAmount(amountSat: amountSat!),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: LnPaymentFee(
                        isCalculatingFees: _isCalculatingFees,
                        feesSat: errorMessage.isEmpty ? _prepareResponse?.feesSat.toInt() : null,
                      ),
                    ),
                    if (widget.lnInvoice.description != null && widget.lnInvoice.description!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: LnPaymentDescription(
                          metadataText: widget.lnInvoice.description!,
                        ),
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
              : errorMessage.isNotEmpty
                  ? SingleButtonBottomBar(
                      stickToBottom: true,
                      text: texts.ln_payment_action_close,
                      onPressed: () {
                        Navigator.of(context).pop();
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
    final texts = context.texts();
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;

    String? message;
    if (_lightningLimits == null) {
      message = texts.payment_limits_fetch_error_message;
    }
    final effectiveMinSat = _lightningLimits!.send.minSat.toInt();
    final effectiveMaxSat = _lightningLimits!.send.maxSat.toInt();
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
    final balance = accountState.walletInfo!.balanceSat.toInt();
    final lnUrlCubit = context.read<LnUrlCubit>();
    return lnUrlCubit.validateLnUrlPayment(BigInt.from(amount), outgoing, _lightningLimits!, balance);
  }
}
