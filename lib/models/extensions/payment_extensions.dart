import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/services/services.dart';

extension PaymentMatching on Payment {
  bool matches(PaymentTrackingConfig config) {
    if (!isValidPaymentState()) {
      return false;
    }

    return switch (config) {
      SendPaymentTrackingConfig() when isOutgoing => _matchingDestination(config.destination),
      ReceivePaymentTrackingConfig() when isIncoming => switch (config.trackingType) {
          PaymentTrackingType.lightningAddress => isLnPayment,
          PaymentTrackingType.bitcoinTransaction => isBitcoinPayment,
          PaymentTrackingType.lightningInvoice => _matchingDestination(config.destination!),
          _ => false
        },
      _ => false
    };
  }

  bool _matchingDestination(String configDestination) => (destination ?? '') == configDestination;

  /// Check if payment status is valid based on direction
  bool isValidPaymentState() => isIncoming ? isPending || isComplete : isComplete;
}

// Extension methods for basic payment properties
extension PaymentProperties on Payment {
  bool get isIncoming => paymentType == PaymentType.receive;
  bool get isOutgoing => paymentType == PaymentType.send;
  bool get isPending => status == PaymentState.pending;
  bool get isComplete => status == PaymentState.complete;
  bool get isBitcoinPayment => details is PaymentDetails_Bitcoin;
  bool get isLnPayment => details is! PaymentDetails_Bitcoin;
  String get direction => paymentType == PaymentType.send ? 'Outgoing' : 'Incoming';
}
