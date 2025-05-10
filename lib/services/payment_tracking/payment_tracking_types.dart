import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

const Duration lnAddressTrackingDelay = Duration(milliseconds: 1600);

/// Types of payment tracking supported by the application
enum PaymentTrackingType { lightningAddress, lightningInvoice, bitcoinTransaction, none }

/// Callback signature for payment received notifications
typedef PaymentCompleteCallback = void Function(bool success);

/// Configuration for payment tracking
class PaymentTrackingConfig {
  final PaymentType paymentType;
  final String? destination;
  final PaymentCompleteCallback onPaymentComplete;
  final PaymentTrackingType trackingType;
  final String? lnAddress;

  factory PaymentTrackingConfig({
    required PaymentType paymentType,
    required String? destination,
    required PaymentCompleteCallback onPaymentComplete,
    PaymentTrackingType? trackingType,
    String? lnAddress,
  }) {
    final PaymentTrackingType resolvedType = (lnAddress?.isNotEmpty ?? false)
        ? PaymentTrackingType.lightningAddress
        : (trackingType ?? PaymentTrackingType.none);

    return PaymentTrackingConfig._internal(
      paymentType: paymentType,
      destination: destination,
      onPaymentComplete: onPaymentComplete,
      trackingType: resolvedType,
      lnAddress: lnAddress,
    );
  }

  const PaymentTrackingConfig._internal({
    required this.paymentType,
    required this.destination,
    required this.onPaymentComplete,
    required this.trackingType,
    required this.lnAddress,
  });

  /// Check if tracking configuration is valid
  ///
  /// - `lnAddress` must be available to track Lightning Address payments
  /// - `destination` must be available to track other payments
  bool get isValid {
    if (trackingType == PaymentTrackingType.none) {
      return false;
    }
    return (isLightningAddress(trackingType) && !isMissingLightningAddress(lnAddress)) ||
        (!isLightningAddress(trackingType) && !isMissingDestination(destination));
  }

  /// Returns the effective tracking type, prioritizing Lightning Address if available.
  PaymentTrackingType get resolvedTrackingType =>
      (lnAddress?.isNotEmpty ?? false) ? PaymentTrackingType.lightningAddress : trackingType;

  Duration get trackingDelay =>
      isLightningAddress(resolvedTrackingType) ? lnAddressTrackingDelay : Duration.zero;
}

bool isIncomingPayment(PaymentType paymentType) => paymentType == PaymentType.receive;
bool isOutgoingPayment(PaymentType paymentType) => paymentType == PaymentType.send;
bool isLightningAddress(PaymentTrackingType type) => type == PaymentTrackingType.lightningAddress;
bool isMissingLightningAddress(String? lnAddress) => lnAddress == null || lnAddress.isEmpty;
bool isMissingDestination(String? destination) => destination?.isNotEmpty != true;

extension PaymentTypeDirection on PaymentType {
  String get direction => this == PaymentType.send ? 'Outgoing' : 'Incoming';
}
