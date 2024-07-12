import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;
import 'package:l_breez/widgets/flushbar.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:logging/logging.dart';

final _log = Logger("EnterPaymentInfoDialog");

class EnterPaymentInfoDialog extends StatefulWidget {
  final GlobalKey paymentItemKey;

  const EnterPaymentInfoDialog({super.key, required this.paymentItemKey});

  @override
  State<StatefulWidget> createState() => EnterPaymentInfoDialogState();
}

class EnterPaymentInfoDialogState extends State<EnterPaymentInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _paymentInfoController = TextEditingController();
  final _paymentInfoFocusNode = FocusNode();

  String _scannerErrorMessage = "";
  String _validatorErrorMessage = "";

  ModalRoute? _loaderRoute;

  @override
  void initState() {
    super.initState();
    _paymentInfoController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24.0, 22.0, 0.0, 16.0),
      title: Text(texts.payment_info_dialog_title),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
      content: _buildPaymentInfoForm(context),
      actions: _buildActions(context),
    );
  }

  Theme _buildPaymentInfoForm(BuildContext context) {
    final themeData = Theme.of(context);
    final texts = context.texts();

    return Theme(
      data: themeData.copyWith(
        inputDecorationTheme: InputDecorationTheme(
          enabledBorder: UnderlineInputBorder(
            borderSide: theme.greyBorderSide,
          ),
        ),
        hintColor: themeData.dialogTheme.contentTextStyle!.color!,
        primaryColor: themeData.textTheme.labelLarge!.color,
        colorScheme: ColorScheme.dark(
          primary: themeData.textTheme.labelLarge!.color!,
          error: themeData.isLightTheme ? Colors.red : themeData.colorScheme.error,
        ),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: texts.payment_info_dialog_hint,
                  suffixIcon: IconButton(
                    padding: const EdgeInsets.only(top: 21.0),
                    alignment: Alignment.bottomRight,
                    icon: Image(
                      image: const AssetImage("src/icon/qr_scan.png"),
                      color: themeData.primaryIconTheme.color,
                      width: 24.0,
                      height: 24.0,
                    ),
                    tooltip: texts.payment_info_dialog_barcode,
                    onPressed: () => _scanBarcode(context),
                  ),
                ),
                focusNode: _paymentInfoFocusNode,
                controller: _paymentInfoController,
                style: TextStyle(
                  color: themeData.primaryTextTheme.headlineMedium!.color,
                ),
                validator: (value) {
                  if (_validatorErrorMessage.isNotEmpty) {
                    return _validatorErrorMessage;
                  }
                  return null;
                },
              ),
              if (_scannerErrorMessage.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _scannerErrorMessage,
                    style: theme.validatorStyle,
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  texts.payment_info_dialog_hint_expanded,
                  style: theme.FieldTextStyle.labelStyle.copyWith(
                    fontSize: 13.0,
                    color:
                        themeData.isLightTheme ? theme.BreezColors.grey[500] : theme.BreezColors.white[200],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final themeData = Theme.of(context);
    final texts = context.texts();

    List<Widget> actions = [
      SimpleDialogOption(
        onPressed: () => Navigator.pop(context),
        child: Text(
          texts.payment_info_dialog_action_cancel,
          style: themeData.primaryTextTheme.labelLarge,
        ),
      )
    ];

    if (_paymentInfoController.text.isNotEmpty) {
      actions.add(
        SimpleDialogOption(
          onPressed: (() async {
            final inputCubit = context.read<InputCubit>();
            final navigator = Navigator.of(context);
            _setLoading(true);

            try {
              await _validateInput(_paymentInfoController.text);
              if (_formKey.currentState!.validate()) {
                _setLoading(false);
                navigator.pop();
                inputCubit.addIncomingInput(_paymentInfoController.text, InputSource.inputField);
              }
            } catch (error) {
              _setLoading(false);
              _log.warning(error.toString(), error);
              _setValidatorErrorMessage(texts.payment_info_dialog_error);
            } finally {
              _setLoading(false);
            }
          }),
          child: Text(
            texts.payment_info_dialog_action_approve,
            style: themeData.primaryTextTheme.labelLarge,
          ),
        ),
      );
    }
    return actions;
  }

  Future _scanBarcode(BuildContext context) async {
    final texts = context.texts();

    FocusScope.of(context).requestFocus(FocusNode());
    String? barcode = await Navigator.pushNamed<String>(context, "/qr_scan");
    if (barcode == null) {
      return;
    }
    if (barcode.isEmpty) {
      if (!context.mounted) return;
      showFlushbar(
        context,
        message: texts.payment_info_dialog_error_qrcode,
      );
      return;
    }
    setState(() {
      _paymentInfoController.text = barcode;
      _scannerErrorMessage = "";
      _setValidatorErrorMessage("");
    });
  }

  Future<void> _validateInput(String input) async {
    final texts = context.texts();
    try {
      _setValidatorErrorMessage("");
      var inputCubit = context.read<InputCubit>();
      final inputType = await inputCubit.parseInput(input: input);
      _log.info("Parsed input type: '${inputType.runtimeType.toString()}");
      // Can't compare against a list of InputType as runtime type comparison is a bit tricky with binding generated enums
      if (!(inputType is InputType_Bolt11 ||
          inputType is InputType_LnUrlPay ||
          inputType is InputType_LnUrlWithdraw ||
          inputType is InputType_LnUrlAuth ||
          inputType is InputType_LnUrlError)) {
        _setValidatorErrorMessage(texts.payment_info_dialog_error_unsupported_input);
      }
    } catch (e) {
      rethrow;
    }
  }

  _setValidatorErrorMessage(String errorMessage) {
    setState(() {
      _validatorErrorMessage = errorMessage;
    });
    _formKey.currentState?.validate();
  }

  void _setLoading(bool visible) {
    if (visible && _loaderRoute == null) {
      _loaderRoute = createLoaderRoute(context);
      Navigator.of(context).push(_loaderRoute!);
      return;
    }

    if (!visible && (_loaderRoute != null && _loaderRoute!.isActive)) {
      _loaderRoute!.navigator?.removeRoute(_loaderRoute!);
      _loaderRoute = null;
    }
  }
}
