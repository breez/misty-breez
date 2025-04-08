import 'package:flutter/services.dart';
import 'package:misty_breez/models/models.dart';

class SatAmountFormFieldFormatter extends TextInputFormatter {
  final RegExp _pattern = RegExp(r'[^\d*]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String raw = newValue.text.replaceAll(_pattern, '');
    if (raw.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    int value;
    try {
      value = int.parse(raw.length > 18 ? raw.substring(0, 18) : raw);
    } catch (ignored) {
      value = 0;
    }

    final String formatted = BitcoinCurrency.sat.format(
      value,
      includeDisplayName: false,
    );

    final int diff = formatted.length - oldValue.text.length;
    int newOffset = newValue.selection.start;
    if (formatted != oldValue.text) {
      if (diff > 1) {
        newOffset += 1;
      }
      if (diff < -1) {
        newOffset -= 1;
      }
    } else {
      newOffset = oldValue.selection.start;
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

// Workaround on https://github.com/flutter/flutter/issues/30369
extension StringFormattedOnSatAmountFormFieldFormatter on String {
  String formatBySatAmountFormFieldFormatter() => SatAmountFormFieldFormatter()
      .formatEditUpdate(const TextEditingValue(), TextEditingValue(text: this))
      .text;
}
