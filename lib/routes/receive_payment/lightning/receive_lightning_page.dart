import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_liquid/breez_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/receive_payment/receive_payment.dart';
import 'package:l_breez/theme/src/theme.dart';
import 'package:l_breez/theme/src/theme_extensions.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/min_font_size.dart';
import 'package:l_breez/utils/payment_validator.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('ReceiveLightningPaymentPage');

class ReceiveLightningPaymentPage extends StatefulWidget {
  static const String routeName = '/receive_lightning';
  static const PaymentMethod paymentMethod = PaymentMethod.lightning;
  static const int pageIndex = 0;

  const ReceiveLightningPaymentPage({super.key});

  @override
  State<StatefulWidget> createState() => ReceiveLightningPaymentPageState();
}

class ReceiveLightningPaymentPageState extends State<ReceiveLightningPaymentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  KeyboardDoneAction _doneAction = KeyboardDoneAction();

  Future<PrepareReceiveResponse>? prepareResponseFuture;
  Future<ReceivePaymentResponse>? receivePaymentResponseFuture;

  @override
  void initState() {
    super.initState();
    if (_amountFocusNode.canRequestFocus) {
      _amountFocusNode.requestFocus();
    }
    _doneAction = KeyboardDoneAction(focusNodes: <FocusNode>[_amountFocusNode]);
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
      body: BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
        builder: (BuildContext context, PaymentLimitsState snapshot) {
          if (snapshot.hasError) {
            return ScrollableErrorMessageWidget(
              title: texts.payment_limits_generic_error_title,
              message: texts.payment_limits_generic_error_message(snapshot.errorMessage),
            );
          }
          final LightningPaymentLimitsResponse? lightningPaymentLimits = snapshot.lightningPaymentLimits;
          if (lightningPaymentLimits == null) {
            return Center(
              child: Loader(
                color: themeData.primaryColor.withOpacity(0.5),
              ),
            );
          }

          return prepareResponseFuture == null
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: SingleChildScrollView(
                    child: _buildForm(lightningPaymentLimits),
                  ),
                )
              : _buildQRCode();
        },
      ),
      bottomNavigationBar: BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
        builder: (BuildContext context, PaymentLimitsState snapshot) {
          return snapshot.hasError
              ? SingleButtonBottomBar(
                  stickToBottom: true,
                  text: texts.invoice_btc_address_action_retry,
                  onPressed: () {
                    final PaymentLimitsCubit paymentLimitsCubit = context.read<PaymentLimitsCubit>();
                    paymentLimitsCubit.fetchLightningLimits();
                  },
                )
              : snapshot.lightningPaymentLimits == null
                  ? const SizedBox.shrink()
                  : prepareResponseFuture == null && receivePaymentResponseFuture == null
                      ? SingleButtonBottomBar(
                          stickToBottom: true,
                          text: texts.invoice_action_create,
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              _createInvoice();
                            }
                          },
                        )
                      : FutureBuilder<PrepareReceiveResponse>(
                          future: prepareResponseFuture,
                          builder: (
                            BuildContext context,
                            AsyncSnapshot<PrepareReceiveResponse> prepareSnapshot,
                          ) {
                            if (prepareSnapshot.hasData) {
                              return FutureBuilder<ReceivePaymentResponse>(
                                future: receivePaymentResponseFuture,
                                builder: (
                                  BuildContext context,
                                  AsyncSnapshot<ReceivePaymentResponse> receiveSnapshot,
                                ) {
                                  if (receiveSnapshot.hasData) {
                                    return SingleButtonBottomBar(
                                      stickToBottom: true,
                                      text: texts.qr_code_dialog_action_close,
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        );
        },
      ),
    );
  }

  Widget _buildForm(LightningPaymentLimitsResponse lightningPaymentLimits) {
    final BreezTranslations texts = context.texts();

    return BlocBuilder<CurrencyCubit, CurrencyState>(
      builder: (BuildContext context, CurrencyState currencyState) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
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
                readOnly: false,
                controller: _amountController,
                validatorFn: (int v) => validatePayment(v, lightningPaymentLimits),
                style: FieldTextStyle.textStyle,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: AutoSizeText(
                  texts.invoice_min_payment_limit(
                    currencyState.bitcoinCurrency.format(
                      lightningPaymentLimits.receive.minSat.toInt(),
                    ),
                  ),
                  style: textStyle,
                  maxLines: 1,
                  minFontSize: MinFontSize(context).minFontSize,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQRCode() {
    final ThemeData themeData = Theme.of(context);

    return FutureBuilder<PrepareReceiveResponse>(
      future: prepareResponseFuture,
      builder: (BuildContext context, AsyncSnapshot<PrepareReceiveResponse> prepareSnapshot) {
        if (prepareSnapshot.hasData) {
          return FutureBuilder<ReceivePaymentResponse>(
            future: receivePaymentResponseFuture,
            builder: (BuildContext context, AsyncSnapshot<ReceivePaymentResponse> receiveSnapshot) {
              return DestinationWidget(
                snapshot: receiveSnapshot,
                title: context.texts().receive_payment_method_lightning_invoice,
                infoWidget: PaymentFeesMessageBox(
                  feesSat: prepareSnapshot.data!.feesSat.toInt(),
                ),
              );
            },
          );
        }

        return Center(
          child: Loader(
            color: themeData.primaryColor.withOpacity(0.5),
          ),
        );
      },
    );
  }

  void _createInvoice() {
    _doneAction.dispose();
    _logger
        .info('Create invoice: description=${_descriptionController.text}, amount=${_amountController.text}');
    final PaymentsCubit paymentsCubit = context.read<PaymentsCubit>();
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();

    final BigInt payerAmountSat =
        BigInt.from(currencyCubit.state.bitcoinCurrency.parse(_amountController.text));
    final Future<PrepareReceiveResponse> prepareReceiveResponse = paymentsCubit.prepareReceivePayment(
      paymentMethod: PaymentMethod.lightning,
      payerAmountSat: payerAmountSat,
    );

    setState(() {
      prepareResponseFuture = prepareReceiveResponse;
    });
    prepareReceiveResponse.then((PrepareReceiveResponse prepareReceiveResponse) {
      setState(() {
        receivePaymentResponseFuture = paymentsCubit.receivePayment(
          prepareResponse: prepareReceiveResponse,
          description: _descriptionController.text,
        );
      });
    });
  }

  String? validatePayment(int amount, LightningPaymentLimitsResponse lightningPaymentLimits) {
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    return PaymentValidator(
      validatePayment: (int amount, bool outgoing) =>
          _validatePayment(amount, outgoing, lightningPaymentLimits),
      currency: currencyCubit.state.bitcoinCurrency,
      texts: context.texts(),
    ).validateIncoming(amount);
  }

  void _validatePayment(int amount, bool outgoing, LightningPaymentLimitsResponse lightningPaymentLimits) {
    final AccountState accountState = context.read<AccountCubit>().state;
    final int balance = accountState.walletInfo!.balanceSat.toInt();
    final LnUrlCubit lnUrlCubit = context.read<LnUrlCubit>();
    return lnUrlCubit.validateLnUrlPayment(BigInt.from(amount), outgoing, lightningPaymentLimits, balance);
  }
}
