import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.lightning:
        return 'Lightning';
      case PaymentMethod.bitcoinAddress:
        return 'BTC Address';
      case PaymentMethod.liquidAddress:
        return 'Liquid Address';
    }
  }
}
