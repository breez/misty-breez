import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_liquid/breez_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_page_result.dart';
import 'package:l_breez/routes/lnurl/withdraw/lnurl_withdraw_dialog.dart';
import 'package:l_breez/routes/receive_payment/lightning/widgets/widgets.dart';
import 'package:l_breez/routes/receive_payment/widgets/address_widget.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/min_font_size.dart';
import 'package:l_breez/utils/payment_validator.dart';
import 'package:l_breez/widgets/amount_form_field/amount_form_field.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:l_breez/widgets/keyboard_done_action.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';
import 'package:l_breez/widgets/transparent_page_route.dart';
import 'package:logging/logging.dart';

final _log = Logger("ReceiveLightningPaymentPage");

class ReceiveLightningPaymentPage extends StatefulWidget {
  final Function(LNURLPageResult? result)? onFinish;
  final LnUrlWithdrawRequestData? requestData;

  static const routeName = "/receive_lightning";
  static const paymentMethod = PaymentMethod.lightning;
  static const pageIndex = 0;

  const ReceiveLightningPaymentPage({super.key, this.onFinish, this.requestData})
      : assert(
          requestData == null || (onFinish != null),
          "If you are using LNURL withdraw, you must provide an onFinish callback.",
        );

  @override
  State<StatefulWidget> createState() => ReceiveLightningPaymentPageState();
}

class ReceiveLightningPaymentPageState extends State<ReceiveLightningPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  var _doneAction = KeyboardDoneAction();

  late LightningPaymentLimitsResponse _lightningLimits;

  PrepareReceiveResponse? prepareResponse;
  Future<ReceivePaymentResponse>? receivePaymentResponse;

  @override
  void initState() {
    super.initState();
    if (_amountFocusNode.canRequestFocus) {
      _amountFocusNode.requestFocus();
    }
    _doneAction = KeyboardDoneAction(focusNodes: [_amountFocusNode]);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        final data = widget.requestData;
        if (data != null) {
          final paymentLimitsState = context.read<PaymentLimitsCubit>().state;
          final minSat = paymentLimitsState.lightningPaymentLimits?.receive.minSat.toInt();
          if (minSat != null && data.maxWithdrawable.toInt() ~/ 1000 < minSat) {
            throw Exception("Payment is below network limit of $minSat sats.");
          }

          final currencyState = context.read<CurrencyCubit>().state;
          _amountController.text = currencyState.bitcoinCurrency.format(
            data.maxWithdrawable.toInt() ~/ 1000,
            includeDisplayName: false,
          );
          _descriptionController.text = data.defaultDescription;
        }
      },
    );
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
      body: BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
        builder: (BuildContext context, PaymentLimitsState snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                texts.reverse_swap_upstream_generic_error_message(snapshot.errorMessage),
                textAlign: TextAlign.center,
              ),
            );
          }
          if (snapshot.lightningPaymentLimits == null) {
            final themeData = Theme.of(context);

            return Center(
              child: Loader(
                color: themeData.primaryColor.withOpacity(0.5),
              ),
            );
          }

          _lightningLimits = snapshot.lightningPaymentLimits!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (receivePaymentResponse == null) ...[
                    BlocBuilder<CurrencyCubit, CurrencyState>(
                      builder: (context, currencyState) {
                        return Form(
                          key: _formKey,
                          child: Scrollbar(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
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
                                          _lightningLimits.receive.minSat.toInt(),
                                        ),
                                      ),
                                      style: textStyle,
                                      maxLines: 1,
                                      minFontSize: MinFontSize(context).minFontSize,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  ],
                  if (receivePaymentResponse != null) ...[
                    FutureBuilder(
                      future: receivePaymentResponse,
                      builder:
                          (BuildContext context, AsyncSnapshot<liquid_sdk.ReceivePaymentResponse> snapshot) {
                        return Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            AddressWidget(
                              snapshot: snapshot,
                              title: "Lightning ${texts.qr_code_dialog_invoice}",
                              type: AddressWidgetType.lightning,
                              feeWidget: ExpiryAndFeeMessage(
                                feesSat: prepareResponse!.feesSat.toInt(),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  ],
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: (receivePaymentResponse == null)
          ? SingleButtonBottomBar(
              stickToBottom: true,
              text: widget.requestData != null ? texts.invoice_action_redeem : texts.invoice_action_create,
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  final data = widget.requestData;
                  if (data != null) {
                    _withdraw(data);
                  } else {
                    _createInvoice();
                  }
                }
              },
            )
          : SingleButtonBottomBar(
              stickToBottom: true,
              text: texts.qr_code_dialog_action_close,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
    );
  }

  Future<void> _withdraw(
    LnUrlWithdrawRequestData data,
  ) async {
    _log.info(
      "Withdraw request: description=${data.defaultDescription}, k1=${data.k1}, "
      "min=${data.minWithdrawable}, max=${data.maxWithdrawable}",
    );
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();

    final navigator = Navigator.of(context);
    navigator.pop();

    showDialog(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (_) => LNURLWithdrawDialog(
        requestData: data,
        amountSats: currencyCubit.state.bitcoinCurrency.parse(
          _amountController.text,
        ),
        onFinish: widget.onFinish!,
      ),
    );
  }

  Future _createInvoice() async {
    _doneAction.dispose();
    _log.info("Create invoice: description=${_descriptionController.text}, amount=${_amountController.text}");
    final paymentsCubit = context.read<PaymentsCubit>();
    final currencyCubit = context.read<CurrencyCubit>();

    final payerAmountSat = BigInt.from(currencyCubit.state.bitcoinCurrency.parse(_amountController.text));
    final prepareReceiveResponse = await paymentsCubit.prepareReceivePayment(
      paymentMethod: PaymentMethod.lightning,
      payerAmountSat: payerAmountSat,
    );

    setState(() {
      prepareResponse = prepareReceiveResponse;
      receivePaymentResponse = paymentsCubit.receivePayment(
        prepareResponse: prepareReceiveResponse,
        description: _descriptionController.text,
      );
    });
  }

  void onPaymentFinished(
    dynamic result,
    ModalRoute currentRoute,
    NavigatorState navigator,
  ) {
    _log.info("Payment finished: $result");
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
      validatePayment: _validatePayment,
      currency: currencyCubit.state.bitcoinCurrency,
      texts: context.texts(),
    ).validateIncoming(amount);
  }

  void _validatePayment(int amount, bool outgoing) {
    final accountState = context.read<AccountCubit>().state;
    final balance = accountState.balance;
    final lnUrlCubit = context.read<LnUrlCubit>();
    return lnUrlCubit.validateLnUrlPayment(BigInt.from(amount), outgoing, _lightningLimits, balance);
  }
}
