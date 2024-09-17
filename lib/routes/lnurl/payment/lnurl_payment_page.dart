import 'dart:convert';
import 'dart:math';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/lnurl/payment/lnurl_payment_info.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_metadata.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/payment_validator.dart';
import 'package:l_breez/widgets/amount_form_field/amount_form_field.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';

class LNURLPaymentPage extends StatefulWidget {
  final LnUrlPayRequestData data;

  const LNURLPaymentPage({super.key, required this.data});

  @override
  State<StatefulWidget> createState() => LNURLPaymentPageState();
}

class LNURLPaymentPageState extends State<LNURLPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

  bool _isFixedAmount = false;
  bool _loading = true;
  String? _errorMessage;
  LightningPaymentLimitsResponse? _lightningLimits;

  @override
  void initState() {
    super.initState();
    _fetchLightningLimits();
    _isFixedAmount = widget.data.minSendable == widget.data.maxSendable;
    if (_isFixedAmount) {
      _setPaymentAmount();
    }
  }

  Future<void> _fetchLightningLimits() async {
    final paymentLimitsCubit = context.read<PaymentLimitsCubit>();
    try {
      final response = await paymentLimitsCubit.fetchLightningLimits();
      _handleLightningPaymentLimitsResponse(response);
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _loading = false;
      });
    }
  }

  void _handleLightningPaymentLimitsResponse(LightningPaymentLimitsResponse response) {
    final effectiveMinSat = max(response.send.minSat.toInt(), widget.data.minSendable.toInt() ~/ 1000);
    if (widget.data.maxSendable.toInt() ~/ 1000 < effectiveMinSat) {
      final currencyCubit = context.read<CurrencyCubit>();
      final currencyState = currencyCubit.state;
      final networkLimit = currencyState.bitcoinCurrency.format(
        effectiveMinSat,
        includeDisplayName: true,
      );
      throw Exception("Payment is below network limit of $networkLimit.");
    }
    setState(() {
      _lightningLimits = response;
      _loading = false;
    });
  }

  void _setPaymentAmount() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currencyCubit = context.read<CurrencyCubit>();
      final currencyState = currencyCubit.state;
      _amountController.text = currencyState.bitcoinCurrency.format(
        (widget.data.maxSendable.toInt() ~/ 1000),
        includeDisplayName: false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.lnurl_fetch_invoice_pay_to_payee(Uri.parse(widget.data.callback).host)),
      ),
      body: Builder(builder: (context) {
        if (_loading) {
          return const Center(
            child: Loader(),
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
          for (var v in json.decode(widget.data.metadataStr)) v[0] as String: v[1],
        };
        String? base64String = metadataMap['image/png;base64'] ?? metadataMap['image/jpeg;base64'];

        final minSendable =
            max(_lightningLimits!.send.minSat.toInt(), widget.data.minSendable.toInt() ~/ 1000);
        final minSendableFormatted = currencyState.bitcoinCurrency.format(minSendable);
        final maxSendable = (widget.data.maxSendable.toInt() ~/ 1000);
        final maxSendableFormatted = currencyState.bitcoinCurrency.format(maxSendable);
        return Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.data.commentAllowed > 0) ...[
                  TextFormField(
                    controller: _commentController,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.done,
                    maxLines: null,
                    maxLength: widget.data.commentAllowed.toInt(),
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    decoration: InputDecoration(
                      labelText: texts.lnurl_payment_page_comment,
                    ),
                  )
                ],
                AmountFormField(
                  context: context,
                  texts: texts,
                  bitcoinCurrency: currencyState.bitcoinCurrency,
                  controller: _amountController,
                  validatorFn: validatePayment,
                  autofocus: !_isFixedAmount,
                  enabled: !_isFixedAmount,
                  readOnly: _isFixedAmount,
                ),
                if (!_isFixedAmount) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: RichText(
                      text: TextSpan(
                        style: FieldTextStyle.labelStyle,
                        children: <TextSpan>[
                          TextSpan(
                            text: texts.lnurl_fetch_invoice_min(
                              minSendableFormatted,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                _amountController.text = minSendableFormatted;
                              },
                          ),
                          TextSpan(
                            text: texts.lnurl_fetch_invoice_and(
                              maxSendableFormatted,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                _amountController.text = maxSendableFormatted;
                              },
                          )
                        ],
                      ),
                    ),
                  ),
                ],
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 48,
                  padding: const EdgeInsets.only(top: 16.0),
                  child: LNURLMetadataText(metadataMap: metadataMap),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 22),
                    child: Center(
                      child: LNURLMetadataImage(
                        base64String: base64String,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: _loading
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
                  text: texts.lnurl_fetch_invoice_action_continue,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final currencyCubit = context.read<CurrencyCubit>();
                      final amount = currencyCubit.state.bitcoinCurrency.parse(_amountController.text);
                      final comment = _commentController.text;
                      Navigator.pop(context, LNURLPaymentInfo(amount: amount, comment: comment));
                    }
                  },
                ),
    );
  }

  String? validatePayment(int amount) {
    final texts = context.texts();
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;

    final maxSendable = widget.data.maxSendable.toInt() ~/ 1000;
    if (amount > maxSendable) {
      return texts.lnurl_payment_page_error_exceeds_limit(maxSendable);
    }

    final minSendable = widget.data.minSendable.toInt() ~/ 1000;
    if (amount < minSendable) {
      return texts.lnurl_payment_page_error_below_limit(minSendable);
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
}
