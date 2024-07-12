import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/models/bitcoin_address_info.dart';
import 'package:l_breez/routes/chainswap/send/validator_holder.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;
import 'package:l_breez/widgets/flushbar.dart';
import 'package:logging/logging.dart';

final _log = Logger("BitcoinAddressTextFormField");

class BitcoinAddressTextFormField extends TextFormField {
  BitcoinAddressTextFormField({
    super.key,
    required BuildContext context,
    required TextEditingController super.controller,
    required ValidatorHolder validatorHolder,
  }) : super(
          decoration: InputDecoration(
            labelText: context.texts().withdraw_funds_btc_address,
            suffixIcon: IconButton(
              alignment: Alignment.bottomRight,
              icon: Image(
                image: const AssetImage("src/icon/qr_scan.png"),
                color: theme.BreezColors.white[500],
                fit: BoxFit.contain,
                width: 24.0,
                height: 24.0,
              ),
              tooltip: context.texts().withdraw_funds_scan_barcode,
              onPressed: () async {
                Navigator.pushNamed<String>(context, "/qr_scan").then(
                  (barcode) {
                    _log.info("Scanned string: '$barcode'");
                    final address = BitcoinAddressInfo.fromScannedString(barcode).address;
                    _log.info("BitcoinAddressInfoFromScannedString: '$address'");
                    if (address == null) return;
                    if (address.isEmpty) {
                      showFlushbar(
                        context,
                        message: context.texts().withdraw_funds_error_qr_code_not_detected,
                      );
                      return;
                    }
                    controller.text = address;
                    _onAddressChanged(context, validatorHolder, address);
                  },
                );
              },
            ),
          ),
          style: theme.FieldTextStyle.textStyle,
          onChanged: (address) => _onAddressChanged(context, validatorHolder, address),
          validator: (address) {
            _log.info("validator called for $address, $validatorHolder");
            if (validatorHolder.valid) {
              return null;
            } else {
              return context.texts().withdraw_funds_error_invalid_address;
            }
          },
        );

  static void _onAddressChanged(
    BuildContext context,
    ValidatorHolder holder,
    String address,
  ) async {
    _log.info("Address changed $address");
    await holder.lock.synchronized(() async {
      _log.info("Calling validator for $address");
      holder.valid = await isValidBitcoinAddress(address);
      _log.info("Address $address validation result $holder");
    });
  }

  static Future<bool> isValidBitcoinAddress(String address) async {
    try {
      final inputType = await parse(input: address);
      return inputType is InputType_BitcoinAddress;
    } catch (e) {
      return false;
    }
  }
}
