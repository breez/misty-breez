import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';

class PaymentMethodDropdown extends StatelessWidget {
  final PaymentMethod currentPaymentMethod;
  final Future<void> Function(PaymentMethod) onPaymentMethodChanged;

  const PaymentMethodDropdown({
    required this.currentPaymentMethod,
    required this.onPaymentMethodChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final Size screenSize = MediaQuery.of(context).size;

    final List<PaymentMethod> allMethods = <PaymentMethod>[
      PaymentMethod.bolt11Invoice,
      PaymentMethod.bitcoinAddress,
    ];

    return PopupMenuButton<PaymentMethod>(
      color: themeData.customData.surfaceBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      constraints: const BoxConstraints(minHeight: 48, maxWidth: 180),
      elevation: 12.0,
      initialValue: currentPaymentMethod,
      onSelected: (PaymentMethod method) {
        if (method != currentPaymentMethod) {
          onPaymentMethodChanged(method);
        }
      },
      position: PopupMenuPosition.under,
      offset: currentPaymentMethod == PaymentMethod.bolt11Invoice ? const Offset(-20, 0) : const Offset(0, 0),
      itemBuilder: (BuildContext context) {
        return allMethods
            .where((PaymentMethod method) => method != currentPaymentMethod)
            .map<PopupMenuItem<PaymentMethod>>((PaymentMethod method) {
              return PopupMenuItem<PaymentMethod>(
                value: method,
                child: Container(
                  width: min(screenSize.width * 0.5, 168),
                  constraints: const BoxConstraints(minHeight: 48, maxWidth: 180),
                  alignment: Alignment.center,
                  child: AutoSizeText(
                    method.displayName.toUpperCase(),
                    style: themeData.appBarTheme.titleTextStyle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    minFontSize: MinFontSize(context).minFontSize,
                    stepGranularity: 0.1,
                  ),
                ),
              );
            })
            .toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(currentPaymentMethod.displayName.toUpperCase(), style: themeData.appBarTheme.titleTextStyle),
            const SizedBox(width: 4.0),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
