import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';

/// Sends L-BTC directly to a Liquid address (no swap involved).
///
/// ponytail: L-BTC only. Addresses that name an asset are rejected upstream in
/// [InputCubit]. Add [PayAmount_Asset] handling here when Misty supports assets.
class LiquidAddressPaymentPage extends StatefulWidget {
  final LiquidAddressData addressData;
  final bool isConfirmation;
  final bool isDrain;
  final int? amountSat;

  static const String routeName = '/liquid_address_payment';

  const LiquidAddressPaymentPage({
    required this.addressData,
    this.isConfirmation = false,
    this.isDrain = false,
    this.amountSat,
    super.key,
  });

  @override
  State<LiquidAddressPaymentPage> createState() => _LiquidAddressPaymentPageState();
}

class _LiquidAddressPaymentPageState extends State<LiquidAddressPaymentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  KeyboardDoneAction _doneAction = KeyboardDoneAction();

  bool _isDrain = false;
  bool _isCalculatingFees = false;
  String errorMessage = '';
  PrepareSendResponse? _prepareResponse;

  /// Amount is fixed once it comes from the BIP21 URI or from the amount step.
  int? get _fixedAmountSat => widget.amountSat ?? widget.addressData.amountSat?.toInt();

  bool get _isFixedAmount => _fixedAmountSat != null;

  @override
  void initState() {
    super.initState();
    _doneAction = KeyboardDoneAction(focusNodes: <FocusNode>[_amountFocusNode]);
    _isDrain = widget.isDrain;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final int? amountSat = _fixedAmountSat;
      if (amountSat != null) {
        _setAmountField(amountSat);
        await _prepareSendPayment(amountSat);
      }
    });
  }

  @override
  void dispose() {
    _doneAction.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _setAmountField(int amountSat) {
    final CurrencyState currencyState = context.read<CurrencyCubit>().state;
    setState(() {
      _amountController.text = currencyState.bitcoinCurrency.format(amountSat, includeDisplayName: false);
    });
  }

  Future<void> _prepareSendPayment(int amountSat) async {
    final BreezTranslations texts = context.texts();
    final PaymentsCubit paymentsCubit = context.read<PaymentsCubit>();
    setState(() {
      _isCalculatingFees = true;
      _prepareResponse = null;
      errorMessage = '';
    });
    try {
      final PayAmount payAmount = _isDrain
          ? const PayAmount_Drain()
          : PayAmount_Bitcoin(receiverAmountSat: BigInt.from(amountSat));
      final PrepareSendResponse response = await paymentsCubit.prepareSendPayment(
        req: PrepareSendRequest(destination: widget.addressData.address, amount: payAmount),
      );
      setState(() {
        _prepareResponse = response;
      });
      if (mounted && _isDrain) {
        final int balanceSat = context.read<AccountCubit>().state.walletInfo!.balanceSat.toInt();
        _setAmountField(balanceSat - (response.feesSat?.toInt() ?? 0));
      }
    } catch (error) {
      setState(() {
        _prepareResponse = null;
        errorMessage = ExceptionHandler.extractMessage(error, texts);
      });
    } finally {
      setState(() {
        _isCalculatingFees = false;
      });
    }
  }

  String? _validateAmount(int amountSat) {
    final BreezTranslations texts = context.texts();
    final int balanceSat = context.read<AccountCubit>().state.walletInfo!.balanceSat.toInt();
    final String? message = amountSat <= 0
        ? texts.invoice_payment_validator_error_payment_below_invoice_limit('0')
        : amountSat > balanceSat
        ? texts.invoice_payment_validator_error_insufficient_local_balance
        : null;
    setState(() {
      errorMessage = message ?? '';
    });
    return message;
  }

  Future<void> _openConfirmationPage() async {
    final CurrencyState currencyState = context.read<CurrencyCubit>().state;
    final int amountSat = currencyState.bitcoinCurrency.parse(_amountController.text);

    final SendPaymentRequest? sendPaymentRequest = await Navigator.of(context).push<SendPaymentRequest?>(
      FadeInRoute<SendPaymentRequest?>(
        builder: (_) => LiquidAddressPaymentPage(
          addressData: widget.addressData,
          isConfirmation: true,
          isDrain: _isDrain,
          amountSat: amountSat,
        ),
      ),
    );
    if (sendPaymentRequest != null && mounted) {
      Navigator.pop(context, sendPaymentRequest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.ln_payment_send_payment_title),
      ),
      body: BlocBuilder<CurrencyCubit, CurrencyState>(
        builder: (BuildContext context, CurrencyState currencyState) {
          final int amountSat = currencyState.bitcoinCurrency.parse(_amountController.text);

          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 40),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (_isFixedAmount)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: LnPaymentHeader(
                          payeeName: '',
                          totalAmount: amountSat,
                          errorMessage: errorMessage,
                        ),
                      ),
                    Container(
                      decoration: ShapeDecoration(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        color: themeData.customData.surfaceBgColor,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildRecipient(themeData),
                          const Divider(height: 32.0, color: Color.fromRGBO(40, 59, 74, 0.5)),
                          if (_isFixedAmount) ...<Widget>[
                            LnPaymentAmount(amountSat: amountSat, hasError: errorMessage.isNotEmpty),
                            const SizedBox(height: 16.0),
                            LnPaymentFee(
                              isCalculatingFees: _isCalculatingFees,
                              feesSat: errorMessage.isEmpty ? _prepareResponse?.feesSat?.toInt() : null,
                            ),
                            if (errorMessage.isNotEmpty) ...<Widget>[
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
                          ] else ...<Widget>[
                            AmountFormField(
                              context: context,
                              texts: texts,
                              bitcoinCurrency: currencyState.bitcoinCurrency,
                              focusNode: _amountFocusNode,
                              autofocus: true,
                              enabled: !_isDrain,
                              controller: _amountController,
                              validatorFn: _validateAmount,
                              errorStyle: FieldTextStyle.labelStyle.copyWith(
                                fontSize: 18.0,
                                color: themeData.colorScheme.error,
                              ),
                              returnFN: (String amountStr) async {
                                if (amountStr.isNotEmpty) {
                                  _setAmountField(currencyState.bitcoinCurrency.parse(amountStr));
                                  _formKey.currentState?.validate();
                                }
                              },
                              onFieldSubmitted: (String amountStr) async {
                                _formKey.currentState?.validate();
                              },
                              style: FieldTextStyle.textStyle,
                            ),
                            _buildDrainSwitch(currencyState, themeData, texts),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _isFixedAmount
          ? _prepareResponse != null
                ? SingleButtonBottomBar(
                    stickToBottom: true,
                    text: texts.ln_payment_action_send,
                    onPressed: () => Navigator.pop(
                      context,
                      SendPaymentRequest(prepareResponse: _prepareResponse!),
                    ),
                  )
                : errorMessage.isNotEmpty
                ? SingleButtonBottomBar(
                    stickToBottom: true,
                    text: texts.ln_payment_action_close,
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : const SizedBox.shrink()
          : SingleButtonBottomBar(
              stickToBottom: true,
              text: texts.lnurl_payment_page_action_next,
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  await _openConfirmationPage();
                }
              },
            ),
    );
  }

  Widget _buildRecipient(ThemeData themeData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          // TODO(erdemyerebasmaz): Add message to Breez-Translations
          'Recipient',
          style: themeData.primaryTextTheme.headlineMedium?.copyWith(fontSize: 18.0, color: Colors.white),
        ),
        const SizedBox(height: 8.0),
        Text(
          widget.addressData.address,
          style: FieldTextStyle.labelStyle.copyWith(fontSize: 14.0),
        ),
      ],
    );
  }

  Widget _buildDrainSwitch(CurrencyState currencyState, ThemeData themeData, BreezTranslations texts) {
    return BlocBuilder<AccountCubit, AccountState>(
      builder: (BuildContext context, AccountState accountState) {
        final int balanceSat = accountState.walletInfo!.balanceSat.toInt();
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
              '${texts.available_balance_label} ${currencyState.bitcoinCurrency.format(balanceSat)}',
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
              activeThumbColor: Colors.white,
              activeTrackColor: themeData.primaryColor,
              onChanged: (bool value) {
                setState(() {
                  _isDrain = value;
                });
                if (value) {
                  _setAmountField(balanceSat);
                } else {
                  setState(() {
                    _amountController.clear();
                  });
                }
                _formKey.currentState?.validate();
              },
            ),
          ),
        );
      },
    );
  }
}
