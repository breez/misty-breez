import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/qr_scan/qr_scan.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/flushbar.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';
import 'package:logging/logging.dart';

final _log = Logger("EnterPaymentInfoPage");

class EnterPaymentInfoPage extends StatefulWidget {
  static const routeName = "/enter_payment_info";
  const EnterPaymentInfoPage({super.key});

  @override
  State<StatefulWidget> createState() => _EnterPaymentInfoPageState();
}

class _EnterPaymentInfoPageState extends State<EnterPaymentInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _paymentInfoController = TextEditingController();

  String errorMessage = "";
  ModalRoute? _loaderRoute;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.payment_info_dialog_title),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _paymentInfoController,
                  decoration: InputDecoration(
                    labelText: texts.payment_info_dialog_hint,
                    suffixIcon: IconButton(
                      padding: const EdgeInsets.only(top: 21.0),
                      alignment: Alignment.bottomRight,
                      icon: Image(
                        image: const AssetImage("assets/icons/qr_scan.png"),
                        color: themeData.primaryIconTheme.color,
                        width: 24.0,
                        height: 24.0,
                      ),
                      tooltip: texts.payment_info_dialog_barcode,
                      onPressed: () => _scanBarcode(),
                    ),
                  ),
                  style: TextStyle(color: themeData.primaryTextTheme.headlineMedium!.color),
                  validator: (value) => errorMessage.isNotEmpty ? errorMessage : null,
                  onFieldSubmitted: (input) async {
                    if (input.isNotEmpty) {
                      setState(() {
                        _paymentInfoController.text = input;
                      });
                      await _validateInput();
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    texts.payment_info_dialog_hint_expanded,
                    style: FieldTextStyle.labelStyle.copyWith(
                      fontSize: 13.0,
                      color: themeData.isLightTheme ? BreezColors.grey[500] : BreezColors.white[200],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SingleButtonBottomBar(
        text: _paymentInfoController.text.isNotEmpty && errorMessage.isEmpty
            ? texts.payment_info_dialog_action_approve
            : texts.payment_info_dialog_action_cancel,
        onPressed: _paymentInfoController.text.isNotEmpty && errorMessage.isEmpty
            ? _onApprovePressed
            : () => Navigator.pop(context),
      ),
    );
  }

  void _scanBarcode() {
    final texts = context.texts();

    Focus.maybeOf(context)?.unfocus();
    Navigator.pushNamed<String>(context, QRScan.routeName).then((barcode) async {
      if (barcode == null || barcode.isEmpty) {
        if (context.mounted) showFlushbar(context, message: texts.payment_info_dialog_error_qrcode);
        return;
      }
      setState(() {
        _paymentInfoController.text = barcode;
      });
      await _validateInput();
    });
  }

  Future<void> _validateInput() async {
    final texts = context.texts();
    final inputCubit = context.read<InputCubit>();
    var errMsg = "";
    setState(() {
      errorMessage = errMsg;
    });
    try {
      final inputType = await inputCubit.parseInput(input: _paymentInfoController.text);
      if (!(inputType is InputType_Bolt11 ||
          inputType is InputType_LnUrlPay ||
          inputType is InputType_LnUrlWithdraw)) {
        errMsg = texts.payment_info_dialog_error_unsupported_input;
      }
      if (inputType is InputType_Bolt11 && inputType.invoice.amountMsat == BigInt.zero) {
        errMsg = texts.payment_request_zero_amount_not_supported;
      }
      if (inputType is InputType_BitcoinAddress) {
        errMsg = "Please use \"Send to BTC Address\" option from main menu.";
      }
    } catch (error) {
      var errStr = error.toString();
      errMsg = errStr.contains("Unrecognized") ? texts.payment_info_dialog_error_unsupported_input : errStr;
    } finally {
      setState(() {
        errorMessage = errMsg;
      });
    }

    _formKey.currentState?.validate();
  }

  Future<void> _onApprovePressed() async {
    final inputCubit = context.read<InputCubit>();

    try {
      _setLoading(true);
      await _validateInput();
      if (_formKey.currentState!.validate()) {
        _setLoading(false);
        if (mounted) Navigator.pop(context);
        inputCubit.addIncomingInput(_paymentInfoController.text, InputSource.inputField);
      }
    } catch (error) {
      _setLoading(false);
      _log.warning(error.toString(), error);
      if (mounted) {
        setState(() {
          errorMessage = context.texts().payment_info_dialog_error;
        });
      }
    }
  }

  void _setLoading(bool visible) {
    if (visible && _loaderRoute == null) {
      _loaderRoute = createLoaderRoute(context);
      Navigator.of(context).push(_loaderRoute!);
    } else if (!visible && _loaderRoute?.isActive == true) {
      _loaderRoute?.navigator?.removeRoute(_loaderRoute!);
      _loaderRoute = null;
    }
  }
}
