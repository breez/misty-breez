import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

class RefundState {
  final List<RefundableSwap>? refundables;
  final String? refundTxId;
  final String? error;
  final bool rebroadcastEnabled;

  RefundState({
    this.refundables,
    this.refundTxId,
    this.error = '',
    this.rebroadcastEnabled = false,
  });

  RefundState.initial() : this();

  RefundState copyWith({
    List<RefundableSwap>? refundables,
    String? refundTxId,
    String? error,
    bool? rebroadcastEnabled,
  }) {
    return RefundState(
      refundables: refundables ?? this.refundables,
      refundTxId: refundTxId ?? this.refundTxId,
      error: error ?? this.error,
      rebroadcastEnabled: rebroadcastEnabled ?? this.rebroadcastEnabled,
    );
  }

  bool get hasRefundables => refundables?.isNotEmpty ?? false;

  /// Returns true if there are any refundable swaps that haven't been refunded yet
  bool get hasNonRefunded =>
      hasRefundables && refundables!.any((RefundableSwap swap) => swap.lastRefundTxId == null);
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
