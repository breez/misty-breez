import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

/// Utility class for payment matching logic
class PaymentMatchers {
  /// Determines if a payment matches destination and type criteria
  static bool isPaymentForDestination(
    Payment payment,
    String destination,
    PaymentType paymentType,
  ) {
    final bool hasMatchingDestination = (payment.destination ?? '') == destination;
    final bool hasMatchingPaymentType = payment.paymentType == paymentType;
    final bool hasValidStatus = isValidPaymentStatus(payment.status, paymentType);

    return hasMatchingDestination && hasMatchingPaymentType && hasValidStatus;
  }

  /// Check if payment status is valid for the given payment type
  static bool isValidPaymentStatus(PaymentState status, PaymentType paymentType) {
    return paymentType == PaymentType.receive
        ? (status == PaymentState.pending || status == PaymentState.complete)
        // For outgoing payments, we only consider payments that are complete,
        // since we're only interested in successful outgoing transactions.
        : (status == PaymentState.complete);
  }
}
