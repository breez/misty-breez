import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/widgets/widgets.dart';

export 'refund_form_amount.dart';

class RefundForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController addressController;
  final RefundableSwap swapInfo;

  const RefundForm({
    required this.formKey,
    required this.addressController,
    required this.swapInfo,
    super.key,
  });

  @override
  State<RefundForm> createState() => _RefundFormState();
}

class _RefundFormState extends State<RefundForm> {
  final ValidatorHolder validatorHolder = ValidatorHolder();

  KeyboardDoneAction _doneAction = KeyboardDoneAction();

  @override
  void initState() {
    super.initState();
    _doneAction = KeyboardDoneAction();
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

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          BitcoinAddressTextFormField(
            controller: widget.addressController,
            validatorHolder: validatorHolder,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(
              height: 32.0,
              color: Color.fromRGBO(40, 59, 74, 0.5),
              indent: 0.0,
              endIndent: 0.0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: RefundFormRefundTxAmount(
              refundTxSat: widget.swapInfo.amountSat.toInt(),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Divider(
              height: 32.0,
              color: Color.fromRGBO(40, 59, 74, 0.5),
              indent: 0.0,
              endIndent: 0.0,
            ),
          ),
          // Original transaction address
          ShareablePaymentRow(
            tilePadding: EdgeInsets.zero,
            dividerColor: Colors.transparent,
            title: '${texts.send_on_chain_original_transaction}:',
            titleTextStyle: themeData.primaryTextTheme.headlineMedium?.copyWith(
              fontSize: 18.0,
              color: Colors.white,
            ),
            sharedValue: widget.swapInfo.swapAddress,
            shouldPop: false,
          ),
        ],
      ),
    );
  }
}
