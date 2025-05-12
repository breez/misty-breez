import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';

/// Types of payment tracking supported by the application
enum PaymentTrackingType { lightningAddress, lightningInvoice, bitcoinTransaction, none }

/// Callback signature for payment received notifications
typedef PaymentCompleteCallback = void Function(bool success);

/// Configuration for payment tracking
abstract class PaymentTrackingConfig {
  final PaymentCompleteCallback onPaymentComplete;
  final String? destination;

  PaymentTrackingConfig._({
    required this.onPaymentComplete,
    this.destination,
  });

  factory PaymentTrackingConfig.send({
    required PaymentCompleteCallback onPaymentComplete,
    required String? destination,
  }) {
    assert(destination?.isNotEmpty == true, 'destination must not be empty for send payments');
    return SendPaymentTrackingConfig._(
      destination: destination!,
      onPaymentComplete: onPaymentComplete,
    );
  }

  // Factory for Receive configuration
  factory PaymentTrackingConfig.receive({
    required PaymentTrackingType trackingType,
    required PaymentCompleteCallback onPaymentComplete,
    required String? destination,
  }) {
    assert(
      trackingType != PaymentTrackingType.none,
      'trackingType must not be null or "none" for incoming payments',
    );
    assert(
      trackingType != PaymentTrackingType.lightningAddress && destination?.isNotEmpty == true,
      'destination must not be empty for non-ln address receive payments',
    );
    return ReceivePaymentTrackingConfig._(
      destination: destination,
      onPaymentComplete: onPaymentComplete,
      trackingType: trackingType,
    );
  }
}

class SendPaymentTrackingConfig extends PaymentTrackingConfig {
  final String _destination;
  final PaymentType paymentType = PaymentType.send;

  SendPaymentTrackingConfig._({
    required String destination,
    required super.onPaymentComplete,
  })  : _destination = destination,
        super._(destination: destination);

  @override
  String get destination => _destination;
}

class ReceivePaymentTrackingConfig extends PaymentTrackingConfig {
  final PaymentType paymentType = PaymentType.receive;
  final PaymentTrackingType trackingType;

  ReceivePaymentTrackingConfig._({
    required super.destination,
    required super.onPaymentComplete,
    required this.trackingType,
  }) : super._();

  // Delay to allow user interaction before showing "Payment Received!" sheet.
  static const Duration lnAddressTrackingDelay = Duration(milliseconds: 1600);

  // LN Address is a static identifier; and if made public, anyone can send payments at any time.
  // Without this delay, a new payment can interrupt the user by showing "Payment Received!" sheet
  // before they have a chance to copy/share their address.
  Duration get trackingDelay =>
      trackingType == PaymentTrackingType.lightningAddress ? lnAddressTrackingDelay : Duration.zero;
}

extension PaymentTypeDirection on PaymentType {
  String get direction => this == PaymentType.send ? 'Outgoing' : 'Incoming';
}

/// PaymentData filter utility functions
class PaymentDataFilters {
  /// Filter for pending incoming Bitcoin payments
  static bool isPendingIncomingBtcPayment(PaymentData payment) =>
      payment.isIncoming && payment.isPending && payment.isBitcoinPayment;

  /// Filter for pending incoming Lightning payments
  static bool isPendingIncomingLnPayment(PaymentData payment) =>
      payment.isIncoming && payment.isPending && payment.isLnPayment;
}

// Extension methods for basic payment properties
extension PaymentProperties on PaymentData {
  bool get isIncoming => paymentType == PaymentType.receive;
  bool get isPending => status == PaymentState.pending;
  bool get isBitcoinPayment => details is PaymentDetails_Bitcoin;
  bool get isLnPayment => details is! PaymentDetails_Bitcoin;
}
