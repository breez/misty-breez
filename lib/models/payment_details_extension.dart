import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/utils/date.dart';

// TODO(erdemyerebasmaz): Ensure that any changes to [PaymentDetails] are reflected here on each extension.
extension PaymentDetailsMapExtension on PaymentDetails {
  T map<T>({
    required T Function() orElse,
    T Function(PaymentDetails_Bitcoin details)? bitcoin,
    T Function(PaymentDetails_Lightning details)? lightning,
    T Function(PaymentDetails_Liquid details)? liquid,
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
      lightning: (PaymentDetails_Lightning details) => <String, dynamic>{
        'type': 'lightning',
        'swapId': details.swapId,
        'description': details.description,
        'preimage': details.preimage,
        'invoice': details.invoice,
        'destinationPubkey': details.destinationPubkey,
        'refundTxId': details.refundTxId,
        'refundTxAmountSat': details.refundTxAmountSat?.toString(),
      },
      liquid: (PaymentDetails_Liquid details) => <String, dynamic>{
        'type': 'liquid',
        'destination': details.destination,
        'description': details.description,
      },
      bitcoin: (PaymentDetails_Bitcoin details) => <String, dynamic>{
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
          liquidExpirationBlockheight: json['liquidExpirationBlockheight'] as int,
          preimage: json['preimage'] as String?,
          invoice: json['invoice'] as String?,
          destinationPubkey: json['destinationPubkey'] as String?,
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
          bitcoinExpirationBlockheight: json['bitcoinExpirationBlockheight'] as int?,
          liquidExpirationBlockheight: json['liquidExpirationBlockheight'] as int?,
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
              lightning: (PaymentDetails_Lightning o) =>
                  o.swapId == (this as PaymentDetails_Lightning).swapId &&
                  o.description == (this as PaymentDetails_Lightning).description &&
                  o.destinationPubkey == (this as PaymentDetails_Lightning).destinationPubkey &&
                  o.preimage == (this as PaymentDetails_Lightning).preimage &&
                  o.invoice == (this as PaymentDetails_Lightning).invoice &&
                  o.refundTxId == (this as PaymentDetails_Lightning).refundTxId &&
                  o.refundTxAmountSat == (this as PaymentDetails_Lightning).refundTxAmountSat,
              liquid: (PaymentDetails_Liquid o) =>
                  o.destination == (this as PaymentDetails_Liquid).destination &&
                  o.description == (this as PaymentDetails_Liquid).description,
              bitcoin: (PaymentDetails_Bitcoin o) =>
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
      lightning: (PaymentDetails_Lightning o) => Object.hash(
        o.swapId,
        o.description,
        o.destinationPubkey,
        o.preimage,
        o.invoice,
        o.refundTxId,
        o.refundTxAmountSat,
      ),
      liquid: (PaymentDetails_Liquid o) => Object.hash(o.destination, o.description),
      bitcoin: (PaymentDetails_Bitcoin o) =>
          Object.hash(o.swapId, o.description, o.refundTxId, o.refundTxAmountSat),
      orElse: () => 0,
    );
  }
}

extension PaymentDetailsExpiryDate on PaymentDetails {
  DateTime? getExpiryDate({required BlockchainInfo? blockchainInfo}) {
    if (blockchainInfo == null) {
      return null;
    }

    final int? expiryBlockheight = map(
      bitcoin: (PaymentDetails_Bitcoin details) => details.bitcoinExpirationBlockheight,
      lightning: (PaymentDetails_Lightning details) => details.liquidExpirationBlockheight,
      orElse: () => null,
    );

    if (expiryBlockheight == null) {
      return null;
    }

    final int? currentTip = map(
      bitcoin: (_) => blockchainInfo.bitcoinTip,
      lightning: (_) => blockchainInfo.liquidTip,
      orElse: () => null,
    );

    if (currentTip == null) {
      return null;
    }

    return map(
      bitcoin: (_) => BreezDateUtils.bitcoinBlockDiffToDate(
        blockHeight: currentTip,
        expiryBlock: expiryBlockheight,
      ),
      lightning: (_) => BreezDateUtils.liquidBlockDiffToDate(
        blockHeight: currentTip,
        expiryBlock: expiryBlockheight,
      ),
      orElse: () => null,
    );
  }
}
