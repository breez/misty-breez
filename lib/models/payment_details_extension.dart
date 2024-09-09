import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

// TODO: Ensure that any changes to [PaymentDetails] are reflected here on each extension.
extension PaymentDetailsMapExtension on PaymentDetails {
  T map<T>({
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

extension PaymentDetailsToJson on PaymentDetails {
  Map<String, dynamic>? toJson() {
    return map(
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

extension PaymentDetailsFromJson on PaymentDetails {
  static PaymentDetails fromJson(Map<String, dynamic> json) {
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
        return PaymentDetails.liquid(
          destination: json['destination'] as String,
          description: json['description'] as String,
        );
    }
  }
}

extension PaymentDetailsExtension on PaymentDetails {
  bool equals(PaymentDetails other) {
    return (identical(this, other)) ||
        other.runtimeType == runtimeType &&
            other.map(
              lightning: (o) =>
                  o.swapId == (this as PaymentDetails_Lightning).swapId &&
                  o.description == (this as PaymentDetails_Lightning).description &&
                  o.preimage == (this as PaymentDetails_Lightning).preimage &&
                  o.bolt11 == (this as PaymentDetails_Lightning).bolt11 &&
                  o.refundTxId == (this as PaymentDetails_Lightning).refundTxId &&
                  o.refundTxAmountSat == (this as PaymentDetails_Lightning).refundTxAmountSat,
              liquid: (o) =>
                  o.destination == (this as PaymentDetails_Liquid).destination &&
                  o.description == (this as PaymentDetails_Liquid).description,
              bitcoin: (o) =>
                  o.swapId == (this as PaymentDetails_Bitcoin).swapId &&
                  o.description == (this as PaymentDetails_Bitcoin).description &&
                  o.refundTxId == (this as PaymentDetails_Bitcoin).refundTxId &&
                  o.refundTxAmountSat == (this as PaymentDetails_Bitcoin).refundTxAmountSat,
              orElse: () => this == other,
            );
  }
}

extension PaymentDetailsHashCode on PaymentDetails {
  int calculateHashCode() {
    return map(
      lightning: (o) =>
          Object.hash(o.swapId, o.description, o.preimage, o.bolt11, o.refundTxId, o.refundTxAmountSat),
      liquid: (o) => Object.hash(o.destination, o.description),
      bitcoin: (o) => Object.hash(o.swapId, o.description, o.refundTxId, o.refundTxAmountSat),
      orElse: () => 0,
    );
  }
}
