import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/chainswap/send/validator_holder.dart';
import 'package:l_breez/routes/qr_scan/qr_scan.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:logging/logging.dart';

final _log = Logger("BitcoinAddressTextFormField");

class BitcoinAddressTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final ValidatorHolder validatorHolder;

  const BitcoinAddressTextFormField({
    super.key,
    required this.controller,
    required this.validatorHolder,
  });

  @override
  BitcoinAddressTextFormFieldState createState() => BitcoinAddressTextFormFieldState();
}

class BitcoinAddressTextFormFieldState extends State<BitcoinAddressTextFormField> {
  final _textFieldKey = GlobalKey<FormFieldState<String>>();
  bool _autoValidate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.controller.text.isNotEmpty) {
        await _validateAddress();
        setState(() {
          _autoValidate = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return TextFormField(
      key: _textFieldKey,
      controller: widget.controller,
      autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: context.texts().withdraw_funds_btc_address,
        suffixIcon: IconButton(
          alignment: Alignment.bottomRight,
          icon: Image(
            image: const AssetImage("src/icon/qr_scan.png"),
            color: BreezColors.white[500],
            fit: BoxFit.contain,
            width: 24.0,
            height: 24.0,
          ),
          tooltip: texts.withdraw_funds_scan_barcode,
          onPressed: () {
            _log.info("Start qr code scan");
            Navigator.pushNamed<String>(context, QRScan.routeName).then(
              (barcode) async {
                _log.info("Scanned string: '$barcode'");
                if (barcode == null) return;
                if (barcode.isEmpty && context.mounted) {
                  showFlushbar(
                    context,
                    message: texts.withdraw_funds_error_qr_code_not_detected,
                  );
                  return;
                }

                widget.controller.text = barcode;
                await _validateAddress();
              },
            );
          },
        ),
      ),
      style: FieldTextStyle.textStyle,
      onChanged: (_) => _validateAddress(),
      validator: (address) {
        _log.info("validator called for $address");
        if (address == null || address.isEmpty) {
          return texts.withdraw_funds_error_invalid_address;
        }
        if (!widget.validatorHolder.valid) {
          return texts.withdraw_funds_error_invalid_address;
        }
        return null;
      },
    );
  }

  Future<void> _validateAddress() async {
    widget.validatorHolder.valid = await widget.validatorHolder.lock.synchronized(
      () => isValidBitcoinAddress(),
    );
    if (mounted) {
      _textFieldKey.currentState?.validate();
    }
  }

  Future<bool> isValidBitcoinAddress() async {
    try {
      final inputType = await parse(input: widget.controller.text);
      return inputType is InputType_BitcoinAddress;
    } catch (e) {
      return false;
    }
  }
}
