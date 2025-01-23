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
