import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/receive_payment/lightning/widgets/widgets.dart';
import 'package:l_breez/routes/receive_payment/widgets/address_qr.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/utils/min_font_size.dart';
import 'package:l_breez/utils/payment_validator.dart';
import 'package:l_breez/widgets/amount_form_field/amount_form_field.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:l_breez/widgets/keyboard_done_action.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';
import 'package:l_breez/widgets/transparent_page_route.dart';
import 'package:service_injector/service_injector.dart';
import 'package:share_plus/share_plus.dart';

class ReceiveLiquidAddressPaymentPage extends StatefulWidget {
  static const routeName = "/receive_bitcoin_address";
  static const paymentMethod = PaymentMethod.liquidAddress;

  const ReceiveLiquidAddressPaymentPage({super.key});

  @override
  State<ReceiveLiquidAddressPaymentPage> createState() => _ReceiveLiquidAddressPaymentPageState();
}

class _ReceiveLiquidAddressPaymentPageState extends State<ReceiveLiquidAddressPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  var _doneAction = KeyboardDoneAction();

  late OnchainPaymentLimitsResponse _onchainPaymentLimits;

  PrepareReceiveResponse? prepareResponse;
  Future<ReceivePaymentResponse>? receivePaymentResponse;

  @override
  void initState() {
    super.initState();
    if (_amountFocusNode.canRequestFocus) {
      _amountFocusNode.requestFocus();
    }
    _doneAction = KeyboardDoneAction(focusNodes: [_amountFocusNode]);
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
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (receivePaymentResponse == null) ...[
              BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
                builder: (BuildContext context, PaymentLimitsState snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                        child: Text(
                          texts.reverse_swap_upstream_generic_error_message(snapshot.errorMessage),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  if (snapshot.onchainPaymentLimits == null) {
                    final themeData = Theme.of(context);

                    return Center(
                      child: Loader(
                        color: themeData.primaryColor.withOpacity(0.5),
                      ),
                    );
                  }

                  _onchainPaymentLimits = snapshot.onchainPaymentLimits!;

                  return BlocBuilder<CurrencyCubit, CurrencyState>(
                    builder: (context, currencyState) {
                      return Form(
                        key: _formKey,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _descriptionController,
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.done,
                                maxLines: null,
                                maxLength: 90,
                                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                                decoration: InputDecoration(
                                  labelText: texts.invoice_description_label,
                                ),
                                style: FieldTextStyle.textStyle,
                              ),
                              AmountFormField(
                                context: context,
                                texts: texts,
                                bitcoinCurrency: currencyState.bitcoinCurrency,
                                focusNode: _amountFocusNode,
                                autofocus: true,
                                controller: _amountController,
                                validatorFn: (v) => validatePayment(v),
                                style: FieldTextStyle.textStyle,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: AutoSizeText(
                                  texts.invoice_min_payment_limit(
                                    currencyState.bitcoinCurrency.format(
                                      _onchainPaymentLimits.receive.minSat.toInt(),
                                    ),
                                  ),
                                  style: textStyle,
                                  maxLines: 1,
                                  minFontSize: MinFontSize(context).minFontSize,
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
            if (receivePaymentResponse != null) ...[
              FutureBuilder(
                future: receivePaymentResponse,
                builder: (BuildContext context, AsyncSnapshot<ReceivePaymentResponse> snapshot) {
                  final themeData = Theme.of(context);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text(texts.invoice_liquid_address_deposit_address),
                            ),
                            Row(
                              children: <Widget>[
                                Tooltip(
                                  message: texts.qr_code_dialog_share,
                                  child: IconButton(
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    padding:
                                        const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 2.0, left: 14.0),
                                    icon: const Icon(IconData(0xe917, fontFamily: 'icomoon')),
                                    color: themeData.primaryTextTheme.labelLarge!.color!,
                                    onPressed: () {
                                      Share.share(snapshot.data!.destination);
                                    },
                                  ),
                                ),
                                Tooltip(
                                  message: texts.qr_code_dialog_copy,
                                  child: IconButton(
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    padding:
                                        const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 14.0, left: 2.0),
                                    icon: const Icon(IconData(0xe90b, fontFamily: 'icomoon')),
                                    color: themeData.primaryTextTheme.labelLarge!.color!,
                                    onPressed: () {
                                      ServiceInjector()
                                          .deviceClient
                                          .setClipboardText(snapshot.data!.destination);
                                      showFlushbar(
                                        context,
                                        message: texts.qr_code_dialog_copied,
                                        duration: const Duration(seconds: 3),
                                      );
                                    },
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                        AnimatedCrossFade(
                          firstChild: LoadingOrError(
                            error: snapshot.error,
                            displayErrorMessage: snapshot.error != null
                                ? extractExceptionMessage(snapshot.error!, texts)
                                : texts.qr_code_dialog_warning_message_error,
                          ),
                          secondChild: snapshot.data == null || prepareResponse == null
                              ? const SizedBox.shrink()
                              : Column(
                                  children: [
                                    AddressQR(bolt11: snapshot.data!.destination, bip21: true),
                                    const Padding(padding: EdgeInsets.only(top: 16.0)),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      child: ExpiryAndFeeMessage(
                                        feesSat: prepareResponse!.feesSat.toInt(),
                                      ),
                                    ),
                                    const Padding(padding: EdgeInsets.only(top: 16.0)),
                                  ],
                                ),
                          duration: const Duration(seconds: 1),
                          crossFadeState:
                              snapshot.data == null ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: (receivePaymentResponse == null)
          ? SingleButtonBottomBar(
              stickToBottom: true,
              text: texts.invoice_action_create,
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  _createSwap();
                }
              },
            )
          : const SizedBox.shrink(),
    );
  }

  Future _createSwap() async {
    _doneAction.dispose();
    final paymentsCubit = context.read<PaymentsCubit>();
    final currencyCubit = context.read<CurrencyCubit>();

    final payerAmountSat = currencyCubit.state.bitcoinCurrency.parse(_amountController.text);
    final prepareResp = await paymentsCubit.prepareReceivePayment(
      paymentMethod: PaymentMethod.liquidAddress,
      payerAmountSat: BigInt.from(payerAmountSat),
    );
    setState(() {
      prepareResponse = prepareResp;
      receivePaymentResponse = paymentsCubit.receivePayment(
        prepareResponse: prepareResponse!,
        description: _descriptionController.text,
      );
    });
    return;
  }

  void onPaymentFinished(
    dynamic result,
    ModalRoute currentRoute,
    NavigatorState navigator,
  ) {
    if (result == true) {
      if (currentRoute.isCurrent) {
        navigator.push(
          TransparentPageRoute((ctx) => const SuccessfulPaymentRoute()),
        );
      }
    } else {
      if (result is String) {
        showFlushbar(context, title: "", message: result);
      }
    }
  }

  String? validatePayment(int amount) {
    var currencyCubit = context.read<CurrencyCubit>();
    return PaymentValidator(
      validatePayment: _validateSwap,
      currency: currencyCubit.state.bitcoinCurrency,
      texts: context.texts(),
    ).validateIncoming(amount);
  }

  void _validateSwap(int amount, bool outgoing) {
    final accountState = context.read<AccountCubit>().state;
    final balance = accountState.balance;
    final chainSwapCubit = context.read<ChainSwapCubit>();
    return chainSwapCubit.validateSwap(BigInt.from(amount), outgoing, _onchainPaymentLimits, balance);
  }
}
