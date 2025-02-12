import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

class RefundState {
  final List<RefundableSwap>? refundables;
  final String? refundTxId;
  final String? error;

  RefundState({
    this.refundables,
    this.refundTxId,
    this.error = '',
  });

  RefundState.initial() : this();

  RefundState copyWith({
    List<RefundableSwap>? refundables,
    String? refundTxId,
    String? error,
  }) {
    return RefundState(
      refundables: refundables ?? this.refundables,
      refundTxId: refundTxId ?? this.refundTxId,
      error: error ?? this.error,
    );
  }

  bool get hasRefundables => refundables?.isNotEmpty ?? false;
}

/// Extension on [SdkEvent] to determine if the event is refund-related.
extension RefundRelatedSdkEvent on SdkEvent {
  /// Returns true if this event is related to a refund.
  ///
  /// For [SdkEvent_PaymentFailed], the [hasRefundables] flag must be true.
  bool isRefundRelated({bool hasRefundables = false}) {
    if (this is SdkEvent_PaymentRefundable ||
        this is SdkEvent_PaymentRefundPending ||
        this is SdkEvent_PaymentRefunded) {
      return true;
    }
    if (this is SdkEvent_PaymentFailed && hasRefundables) {
      return true;
    }
    return false;
  }
}
