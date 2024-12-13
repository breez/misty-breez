import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('BitcoinAddressTextFormField');

class BitcoinAddressTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final ValidatorHolder validatorHolder;

  const BitcoinAddressTextFormField({
    required this.controller,
    required this.validatorHolder,
    super.key,
  });

  @override
  BitcoinAddressTextFormFieldState createState() => BitcoinAddressTextFormFieldState();
}

class BitcoinAddressTextFormFieldState extends State<BitcoinAddressTextFormField> {
  final GlobalKey<FormFieldState<String>> _textFieldKey = GlobalKey<FormFieldState<String>>();
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
    final BreezTranslations texts = context.texts();

    return TextFormField(
      key: _textFieldKey,
      controller: widget.controller,
      autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        prefixIconConstraints: BoxConstraints.tight(
          const Size(16, 56),
        ),
        prefixIcon: const SizedBox.shrink(),
        contentPadding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
        border: const OutlineInputBorder(),
        labelText: texts.withdraw_funds_btc_address,
        suffixIcon: IconButton(
          alignment: Alignment.bottomRight,
          padding: const EdgeInsets.only(bottom: 12.0, right: 12.0),
          icon: Image(
            image: const AssetImage('assets/icons/qr_scan.png'),
            color: BreezColors.white[500],
            fit: BoxFit.contain,
            width: 24.0,
            height: 24.0,
          ),
          tooltip: texts.bitcoin_address_scan_tooltip,
          onPressed: () {
            _logger.info('Start qr code scan');
            Navigator.pushNamed<String>(context, QRScanView.routeName).then(
              (String? barcode) async {
                _logger.info("Scanned string: '$barcode'");
                if (barcode == null) {
                  return;
                }
                if (barcode.isEmpty && context.mounted) {
                  showFlushbar(
                    context,
                    message: texts.qr_code_not_detected_error,
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
      validator: (String? address) {
        _logger.info('validator called for $address');
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
    final InputCubit inputCubit = context.read<InputCubit>();
    try {
      final InputType inputType = await inputCubit.parseInput(input: widget.controller.text);
      return inputType is InputType_BitcoinAddress;
    } catch (e) {
      return false;
    }
  }
}
