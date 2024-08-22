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

extension PaymentDetailsToJson on PaymentDetails? {
  Map<String, dynamic>? toJson() {
    return this?.maybeMap(
      lightning: (details) => {
        'type': 'lightning',
        'swapId': details.swapId,
        'description': details.description,
        'preimage': details.preimage,
        'bolt11': details.bolt11,
        'refundTxId': details.refundTxId,
        'refundTxAmountSat': details.refundTxAmountSat?.toString(),
      },
      liquid: (details) => {
        'type': 'liquid',
        'destination': details.destination,
        'description': details.description,
      },
      bitcoin: (details) => {
        'type': 'bitcoin',
        'swapId': details.swapId,
        'description': details.description,
        'refundTxId': details.refundTxId,
        'refundTxAmountSat': details.refundTxAmountSat?.toString(),
      },
      orElse: () => null,
    );
  }
}

extension PaymentDetailsFromJson on PaymentDetails? {
  static PaymentDetails? fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'lightning':
        return PaymentDetails.lightning(
          swapId: json['swapId'] as String,
          description: json['description'] as String,
          preimage: json['preimage'] as String?,
          bolt11: json['bolt11'] as String?,
          refundTxId: json['refundTxId'] as String?,
          refundTxAmountSat:
              json['refundTxAmountSat'] != null ? BigInt.parse(json['refundTxAmountSat'] as String) : null,
        );
      case 'liquid':
        return PaymentDetails.liquid(
          destination: json['destination'] as String,
          description: json['description'] as String,
        );
      case 'bitcoin':
        return PaymentDetails.bitcoin(
          swapId: json['swapId'] as String,
          description: json['description'] as String,
          refundTxId: json['refundTxId'] as String?,
          refundTxAmountSat:
              json['refundTxAmountSat'] != null ? BigInt.parse(json['refundTxAmountSat'] as String) : null,
        );
      default:
        return null;
    }
  }
}
