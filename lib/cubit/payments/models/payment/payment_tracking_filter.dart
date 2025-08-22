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
      // TODO(erdemyerebasmaz): Cleanup isBitcoinPayment workaround once SDK includes destination or swap ID on resulting payment.
      // Depends on: https://github.com/breez/breez-sdk-liquid/issues/913
      // Treat any incoming BTC payment as valid until we can match it via destination (BIP21 URI) or swap ID.
      // TODO(erdemyerebasmaz): Issue above is resolved but not tested yet.
      /*
      final PaymentDetails paymentDetails = payment.details;
      if (paymentDetails is PaymentDetails_Bitcoin) {
        return paymentDetails.bitcoinAddress == expectedDestination;
      }
      */
      return trackingConfig.isBitcoinPayment
          ? payment.details is PaymentDetails_Bitcoin
          : payment.destination == trackingConfig.expectedDestination;
    }
    return false;
  }
}

extension PaymentTrackingId on Payment {
  String get trackingId => txId ?? destination ?? '';
}
