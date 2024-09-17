import 'dart:math';

import 'package:breez_liquid/breez_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_page_result.dart';
import 'package:l_breez/routes/lnurl/withdraw/lnurl_withdraw_dialog.dart';
import 'package:l_breez/routes/receive_payment/widgets/destination_widget/destination_widget.dart';
import 'package:l_breez/routes/receive_payment/widgets/payment_info_message_box/payment_fees_message_box.dart';
import 'package:l_breez/theme/src/theme.dart';
import 'package:l_breez/theme/src/theme_extensions.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/payment_validator.dart';
import 'package:l_breez/widgets/amount_form_field/amount_form_field.dart';
import 'package:l_breez/widgets/keyboard_done_action.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';
import 'package:logging/logging.dart';

final _log = Logger("LnUrlWithdrawPage");

class LnUrlWithdrawPage extends StatefulWidget {
  final Function(LNURLPageResult? result) onFinish;
  final LnUrlWithdrawRequestData requestData;

  static const routeName = "/lnurl_withdraw";
  static const paymentMethod = PaymentMethod.lightning;

  const LnUrlWithdrawPage({super.key, required this.onFinish, required this.requestData});

  @override
  State<StatefulWidget> createState() => LnUrlWithdrawPageState();
}

class LnUrlWithdrawPageState extends State<LnUrlWithdrawPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  var _doneAction = KeyboardDoneAction();

  late LightningPaymentLimitsResponse _lightningLimits;

  PrepareReceiveResponse? prepareResponse;
  Future<ReceivePaymentResponse>? receivePaymentResponse;

  bool isBelowPaymentLimit = false;

  @override
  void initState() {
    super.initState();
    _doneAction = KeyboardDoneAction(focusNodes: [_amountFocusNode]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePageData();
    });
  }

  void _initializePageData() {
    final data = widget.requestData;
    final isFixedAmount = data.minWithdrawable == data.maxWithdrawable;
    if (!isFixedAmount) {
      if (_amountFocusNode.canRequestFocus) {
        _amountFocusNode.requestFocus();
      }
    }
    final paymentLimitsState = context.read<PaymentLimitsCubit>().state;
    final minSat = paymentLimitsState.lightningPaymentLimits?.receive.minSat.toInt();
    if (minSat != null && data.maxWithdrawable.toInt() ~/ 1000 < minSat) {
      isBelowPaymentLimit = true;
    }

    final currencyState = context.read<CurrencyCubit>().state;
    _amountController.text = currencyState.bitcoinCurrency.format(
      data.maxWithdrawable.toInt() ~/ 1000,
      includeDisplayName: false,
    );
    _descriptionController.text = data.defaultDescription;
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

          final minWithdrawable = max(
            _lightningLimits.receive.minSat.toInt(),
            widget.requestData.minWithdrawable.toInt() ~/ 1000,
          );
          isBelowPaymentLimit = widget.requestData.maxWithdrawable.toInt() ~/ 1000 < minWithdrawable;

          if (isBelowPaymentLimit) {
            return BlocBuilder<CurrencyCubit, CurrencyState>(
              builder: (context, currencyState) {
                return Center(
                  child: Text(
                    texts.invoice_payment_validator_error_payment_below_invoice_limit(
                      currencyState.bitcoinCurrency.format(minWithdrawable),
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            );
          }

          final maxWithdrawable = min(
            _lightningLimits.receive.maxSat.toInt(),
            widget.requestData.maxWithdrawable.toInt() ~/ 1000,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: SingleChildScrollView(
              // TODO: Extract these into widgets
              child: receivePaymentResponse == null
                  ? _buildForm(
                      minWithdrawable: minWithdrawable,
                      maxWithdrawable: maxWithdrawable,
                    )
                  : _buildQRCode(),
            ),
          );
        },
      ),
      bottomNavigationBar: (receivePaymentResponse == null && !isBelowPaymentLimit)
          ? SingleButtonBottomBar(
              stickToBottom: true,
              text: texts.invoice_action_redeem,
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  _withdraw();
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

  Widget _buildForm({
    required int minWithdrawable,
    required int maxWithdrawable,
  }) {
    final texts = context.texts();
    final data = widget.requestData;

    return BlocBuilder<CurrencyCubit, CurrencyState>(
      builder: (context, currencyState) {
        final isFixedAmount = data.minWithdrawable == data.maxWithdrawable;
        final minWithdrawableFormatted = currencyState.bitcoinCurrency.format(minWithdrawable);
        final maxWithdrawableFormatted = currencyState.bitcoinCurrency.format(maxWithdrawable);

        final isFixedAmountWithinLimits = minWithdrawable == maxWithdrawable;
        if (!isFixedAmountWithinLimits) {
          return BlocBuilder<CurrencyCubit, CurrencyState>(
            builder: (context, currencyState) {
              return Center(
                child: Text(
                  texts.invoice_payment_validator_error_payment_below_invoice_limit(
                    minWithdrawableFormatted,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          );
        }

        return Form(
          key: _formKey,
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.defaultDescription.isNotEmpty) ...[
                    TextFormField(
                      controller: _descriptionController,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.done,
                      maxLines: null,
                      readOnly: true,
                      focusNode: AlwaysDisabledFocusNode(),
                      decoration: InputDecoration(
                        labelText: texts.payment_details_dialog_action_for_payment_description,
                      ),
                      style: FieldTextStyle.textStyle,
                    )
                  ],
                  AmountFormField(
                    context: context,
                    texts: texts,
                    bitcoinCurrency: currencyState.bitcoinCurrency,
                    focusNode: isFixedAmount ? AlwaysDisabledFocusNode() : _amountFocusNode,
                    autofocus: !(isFixedAmount),
                    readOnly: isFixedAmount,
                    controller: _amountController,
                    validatorFn: (v) => validatePayment(v),
                    style: FieldTextStyle.textStyle,
                  ),
                  (isFixedAmount)
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: RichText(
                            text: TextSpan(
                              style: FieldTextStyle.labelStyle,
                              children: <TextSpan>[
                                TextSpan(
                                  text: texts.lnurl_fetch_invoice_min(
                                    minWithdrawableFormatted,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _pasteAmount(currencyState, minWithdrawable),
                                ),
                                TextSpan(
                                  text: texts.lnurl_fetch_invoice_and(maxWithdrawableFormatted),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => _pasteAmount(currencyState, maxWithdrawable),
                                ),
                              ],
                            ),
                          ),
                        )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQRCode() {
    return FutureBuilder(
      future: receivePaymentResponse,
      builder: (BuildContext context, AsyncSnapshot<ReceivePaymentResponse> snapshot) {
        return DestinationWidget(
          snapshot: snapshot,
          title: context.texts().receive_payment_method_lightning_invoice,
          infoWidget: PaymentFeesMessageBox(
            feesSat: prepareResponse!.feesSat.toInt(),
          ),
        );
      },
    );
  }

  Future<void> _withdraw() async {
    final data = widget.requestData;
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
        onFinish: widget.onFinish,
      ),
    );
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

  void _pasteAmount(CurrencyState currencyState, int amount) {
    setState(() {
      _amountController.text = currencyState.bitcoinCurrency.format(
        amount,
        includeDisplayName: false,
        userInput: true,
      );
    });
  }
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
