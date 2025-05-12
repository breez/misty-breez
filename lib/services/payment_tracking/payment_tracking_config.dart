import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

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
      trackingType == PaymentTrackingType.lightningAddress ? true : destination?.isNotEmpty == true,
      'destination must not be empty for non-ln address receive payments',
    );
    return ReceivePaymentTrackingConfig._(
      destination: destination,
      onPaymentComplete: onPaymentComplete,
      trackingType: trackingType,
    );
  }

  String get infoMessage;
  String? successMessage(Payment payment);
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

  @override
  String get infoMessage => 'Outgoing payment to $destination';

  @override
  String successMessage(Payment payment) {
    return 'Sent Payment! Destination: $destination';
  }
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

  @override
  String get infoMessage {
    final bool hasDestination = destination?.isNotEmpty == true;

    return switch (trackingType) {
      PaymentTrackingType.lightningInvoice ||
      PaymentTrackingType.bitcoinTransaction when hasDestination =>
        'Incoming invoice to $destination.',
      PaymentTrackingType.lightningInvoice => 'Incoming Lightning payment.',
      PaymentTrackingType.bitcoinTransaction => 'Incoming Bitcoin payment.',
      PaymentTrackingType.lightningAddress => 'Incoming Lightning Address payment.',
      _ => 'Incoming payment.',
    };
  }

  @override
  String successMessage(Payment payment) {
    return switch (trackingType) {
      PaymentTrackingType.lightningAddress => 'Received Lightning Payment!',
      PaymentTrackingType.bitcoinTransaction => 'Received Bitcoin Payment! Destination: $destination',
      PaymentTrackingType.lightningInvoice => 'Received Lightning Payment! Destination: $destination',
      _ => '',
    };
  }
}
