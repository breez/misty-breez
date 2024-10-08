import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/chainswap/send/validator_holder.dart';
import 'package:l_breez/routes/chainswap/send/widgets/bitcoin_address_text_form_field.dart';
import 'package:l_breez/routes/refund/refund_confirmation_page.dart';
import 'package:l_breez/routes/refund/widgets/widgets.dart';
import 'package:l_breez/theme/src/theme.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/collapsible_list_item.dart';
import 'package:l_breez/widgets/route.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';

class RefundPage extends StatefulWidget {
  final RefundableSwap swapInfo;

  static const routeName = "/refund_page";

  const RefundPage({required this.swapInfo, super.key});

  @override
  State<StatefulWidget> createState() => RefundPageState();
}

class RefundPageState extends State<RefundPage> {
  final TextEditingController _addressController = TextEditingController();
  final ValidatorHolder _validatorHolder = ValidatorHolder();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const back_button.BackButton(),
        title: Text(texts.get_refund_title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    BitcoinAddressTextFormField(
                      controller: _addressController,
                      validatorHolder: _validatorHolder,
                    ),
                    const SizedBox(height: 12.0),
                    RefundItemAmount(widget.swapInfo.amountSat.toInt()),
                    CollapsibleListItem(
                      title: texts.send_on_chain_original_transaction,
                      userStyle: FieldTextStyle.textStyle,
                      sharedValue: widget.swapInfo.swapAddress,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SingleButtonBottomBar(
        text: texts.get_refund_action_continue,
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            Navigator.of(context).push(
              FadeInRoute(
                builder: (_) => RefundConfirmationPage(
                  amountSat: widget.swapInfo.amountSat.toInt(),
                  toAddress: _addressController.text,
                  swapAddress: widget.swapInfo.swapAddress,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
