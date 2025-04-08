import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/models/models.dart';

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
    final List<DropdownMenuItem<PaymentMethod>> items =
        <PaymentMethod>[PaymentMethod.lightning, PaymentMethod.bitcoinAddress]
            .map<DropdownMenuItem<PaymentMethod>>(
              (PaymentMethod method) => DropdownMenuItem<PaymentMethod>(
                value: method,
                child: Text(method.displayName),
              ),
            )
            .toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text('Receive with '),
        DropdownButton<PaymentMethod>(
          value: currentPaymentMethod,
          underline: const SizedBox.shrink(),
          style: Theme.of(context).appBarTheme.titleTextStyle,
          onChanged: (PaymentMethod? newValue) {
            if (newValue != null && newValue != currentPaymentMethod) {
              onPaymentMethodChanged(newValue);
            }
          },
          items: items,
          menuMaxHeight: 200,
        ),
      ],
    );
  }
}
