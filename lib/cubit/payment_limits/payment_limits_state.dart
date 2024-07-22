import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

class PaymentLimitsState {
  final LightningPaymentLimitsResponse? lightningPaymentLimits;
  final OnchainPaymentLimitsResponse? onchainPaymentLimits;
  final String errorMessage;

  PaymentLimitsState({
    this.lightningPaymentLimits,
    this.onchainPaymentLimits,
    this.errorMessage = "",
  });

  PaymentLimitsState.initial() : this();

  bool get hasError => errorMessage.isNotEmpty;

  PaymentLimitsState copyWith({
    LightningPaymentLimitsResponse? lightningPaymentLimits,
    OnchainPaymentLimitsResponse? onchainPaymentLimits,
    String? errorMessage,
  }) {
    return PaymentLimitsState(
      lightningPaymentLimits: lightningPaymentLimits ?? this.lightningPaymentLimits,
      onchainPaymentLimits: onchainPaymentLimits ?? this.onchainPaymentLimits,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
