import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/payments/models/payment/payment_tracking_config.dart';

/// A filter utility for tracking incoming payments
class PaymentTrackingFilter {
  final PaymentTrackingConfig trackingConfig;
  final Set<String> excludedIds;

  const PaymentTrackingFilter({required this.trackingConfig, required this.excludedIds});

  bool passes(Payment payment) =>
      _isNewPayment(payment) &&
      _isReceivePayment(payment) &&
      _hasValidState(payment) &&
      _matchesConfig(payment);

  bool _isNewPayment(Payment payment) => !excludedIds.contains(payment.trackingId);

  bool _isReceivePayment(Payment payment) => payment.paymentType == PaymentType.receive;

  bool _hasValidState(Payment payment) =>
      payment.status == PaymentState.pending || payment.status == PaymentState.complete;

  bool _matchesConfig(Payment payment) {
    if (trackingConfig.lnAddress != null) {
      return payment.details is PaymentDetails_Lightning;
    }
    if (trackingConfig.expectedDestination != null) {
      final PaymentDetails paymentDetails = payment.details;
      if (paymentDetails is PaymentDetails_Bitcoin) {
        return paymentDetails.bitcoinAddress == trackingConfig.expectedDestination;
      }
      return payment.destination == trackingConfig.expectedDestination;
    }
    return false;
  }
}

extension PaymentTrackingId on Payment {
  String get trackingId => txId ?? destination ?? '';
}
