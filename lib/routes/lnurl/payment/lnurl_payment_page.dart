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
import 'package:logging/logging.dart';

final _log = Logger("LNURLPaymentPage");

class LNURLPaymentPage extends StatefulWidget {
  final LnUrlPayRequestData data;
  /*TODO: Add domain information to parse results #118(https://github.com/breez/breez-sdk/issues/118)
  final String domain;
  TODO: Add support for LUD-18: Payer identity in payRequest protocol(https://github.com/breez/breez-sdk/issues/117)
  final PayerDataRecordField? name;
  final AuthRecord? auth;
  final PayerDataRecordField? email;
  final PayerDataRecordField? identifier;
 */

  const LNURLPaymentPage({
    required this.data,
    /*
    required this.domain,
    this.name,
    this.auth,
    this.email,
    this.identifier,
     */

    super.key,
  });

  @override
  State<StatefulWidget> createState() => LNURLPaymentPageState();
}

class LNURLPaymentPageState extends State<LNURLPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();
  /*
  final _nameController = TextEditingController();
  final _k1Controller = TextEditingController();
  final _emailController = TextEditingController();
  final _identifierController = TextEditingController();
   */
  late final bool fixedAmount;
  late LightningPaymentLimitsResponse _lightningLimits;

  @override
  void initState() {
    super.initState();
    final paymentLimitsCubit = context.read<PaymentLimitsCubit>();
    final paymentLimitsState = paymentLimitsCubit.state;
    final minSat = paymentLimitsState.lightningPaymentLimits?.send.minSat.toInt();
    if (minSat != null && widget.data.maxSendable.toInt() ~/ 1000 < minSat) {
      throw Exception("Payment is below network limit of $minSat sats.");
    }
    fixedAmount = widget.data.minSendable == widget.data.maxSendable;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        if (fixedAmount) {
          final currencyCubit = context.read<CurrencyCubit>();
          final currencyState = currencyCubit.state;
          _amountController.text = currencyState.bitcoinCurrency.format(
            (widget.data.maxSendable.toInt() ~/ 1000),
            includeDisplayName: false,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final currencyCubit = context.read<CurrencyCubit>();
    final currencyState = currencyCubit.state;
    final metadataMap = {
      for (var v in json.decode(widget.data.metadataStr)) v[0] as String: v[1],
    };
    String? base64String = metadataMap['image/png;base64'] ?? metadataMap['image/jpeg;base64'];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: const back_button.BackButton(),
        // Todo: Use domain from request data
        title: Text(texts.lnurl_fetch_invoice_pay_to_payee(Uri.parse(widget.data.callback).host)),
      ),
      body: BlocBuilder<PaymentLimitsCubit, PaymentLimitsState>(
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
          if (snapshot.lightningPaymentLimits == null) {
            final themeData = Theme.of(context);

            return Center(
              child: Loader(
                color: themeData.primaryColor.withOpacity(0.5),
              ),
            );
          }

          _lightningLimits = snapshot.lightningPaymentLimits!;

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
                    autofocus: !fixedAmount,
                    enabled: !fixedAmount,
                    readOnly: fixedAmount,
                  ),
                  if (!fixedAmount) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: RichText(
                        text: TextSpan(
                          style: FieldTextStyle.labelStyle,
                          children: <TextSpan>[
                            TextSpan(
                              text: texts.lnurl_fetch_invoice_min(
                                currencyState.bitcoinCurrency.format(
                                  max(
                                    _lightningLimits.send.minSat.toInt(),
                                    widget.data.minSendable.toInt() ~/ 1000,
                                  ),
                                ),
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _amountController.text = currencyState.bitcoinCurrency.format(
                                    (widget.data.minSendable.toInt() ~/ 1000),
                                    includeDisplayName: false,
                                  );
                                },
                            ),
                            TextSpan(
                              text: texts.lnurl_fetch_invoice_and(
                                currencyState.bitcoinCurrency.format(
                                  (widget.data.maxSendable.toInt() ~/ 1000),
                                ),
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _amountController.text = currencyState.bitcoinCurrency.format(
                                    (widget.data.maxSendable.toInt() ~/ 1000),
                                    includeDisplayName: false,
                                  );
                                },
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                  /*
                  if (widget.name?.mandatory == true) ...[
                    TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      validator: (value) => value != null ? null : texts.breez_avatar_dialog_your_name,
                    )
                  ],
                  if (widget.auth?.mandatory == true) ...[
                    TextFormField(
                      controller: _k1Controller,
                      keyboardType: TextInputType.text,
                      validator: (value) => value != null ? null : texts.lnurl_payment_page_enter_k1,
                    )
                  ],
                  if (widget.email?.mandatory == true) ...[
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => value != null
                          ? EmailValidator.validate(value)
                              ? null
                              : texts.order_card_country_email_invalid
                          : texts.order_card_country_email_empty,
                    )
                  ],
                  if (widget.identifier?.mandatory == true) ...[
                    TextFormField(
                      controller: _identifierController,
                    )
                  ],
                   */
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
        },
      ),
      bottomNavigationBar: SingleButtonBottomBar(
        stickToBottom: true,
        text: texts.lnurl_fetch_invoice_action_continue,
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            final currencyCubit = context.read<CurrencyCubit>();
            final amount = currencyCubit.state.bitcoinCurrency.parse(_amountController.text);
            final comment = _commentController.text;
            _log.info("LNURL payment of $amount sats where "
                "min is ${widget.data.minSendable.toInt() ~/ 1000} sats "
                "and max is ${widget.data.maxSendable.toInt() ~/ 1000} sats."
                "with comment $comment");
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
    return lnUrlCubit.validateLnUrlPayment(BigInt.from(amount), outgoing, _lightningLimits, balance);
  }
}
