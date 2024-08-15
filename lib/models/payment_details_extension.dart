import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

extension PaymentDetailsMaybeMapExtension on PaymentDetails? {
  T maybeMap<T>({
    T Function(PaymentDetails_Bitcoin details)? bitcoin,
    T Function(PaymentDetails_Lightning details)? lightning,
    T Function(PaymentDetails_Liquid details)? liquid,
    required T Function() orElse,
  }) {
    if (this is PaymentDetails_Bitcoin) {
      return bitcoin != null ? bitcoin(this as PaymentDetails_Bitcoin) : orElse();
    } else if (this is PaymentDetails_Lightning) {
      return lightning != null ? lightning(this as PaymentDetails_Lightning) : orElse();
    } else if (this is PaymentDetails_Liquid) {
      return liquid != null ? liquid(this as PaymentDetails_Liquid) : orElse();
    } else {
      return orElse();
    }
  }
}
