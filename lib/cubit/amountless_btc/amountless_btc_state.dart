import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

class AmountlessBtcState {
  final String? address;
  final int? estimateBaseFeeSat;
  final double? estimateProportionalFee;
  final bool isLoading;
  final Object? error;

  final List<Payment> paymentsWaitingFeeAcceptance;
  final Map<String, FetchPaymentProposedFeesResponse> proposedFeesMap;
  final bool isLoadingPayments;
  final bool isReviewingFees;

  const AmountlessBtcState({
    this.address,
    this.estimateBaseFeeSat,
    this.estimateProportionalFee,
    this.isLoading = false,
    this.error,
    this.paymentsWaitingFeeAcceptance = const <Payment>[],
    this.proposedFeesMap = const <String, FetchPaymentProposedFeesResponse>{},
    this.isLoadingPayments = false,
    this.isReviewingFees = false,
  });

  AmountlessBtcState.initial() : this();

  AmountlessBtcState copyWith({
    String? address,
    int? estimateBaseFeeSat,
    double? estimateProportionalFee,
    bool? isLoading,
    Object? error,
    List<Payment>? paymentsWaitingFeeAcceptance,
    Map<String, FetchPaymentProposedFeesResponse>? proposedFeesMap,
    bool? isLoadingPayments,
    bool? isReviewingFees,
  }) => AmountlessBtcState(
    address: address ?? this.address,
    estimateBaseFeeSat: estimateBaseFeeSat ?? this.estimateBaseFeeSat,
    estimateProportionalFee: estimateProportionalFee ?? this.estimateProportionalFee,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    paymentsWaitingFeeAcceptance: paymentsWaitingFeeAcceptance ?? this.paymentsWaitingFeeAcceptance,
    proposedFeesMap: proposedFeesMap ?? this.proposedFeesMap,
    isLoadingPayments: isLoadingPayments ?? this.isLoadingPayments,
    isReviewingFees: isReviewingFees ?? this.isReviewingFees,
  );

  bool get hasValidAddress => address != null && address!.isNotEmpty;
  bool get hasError => error != null;
  bool get hasPaymentsWaitingFeeAcceptance => paymentsWaitingFeeAcceptance.isNotEmpty;
  bool get hasProposedFees => proposedFeesMap.isNotEmpty;

  @override
  String toString() =>
      'AmountlessBtcState('
      'address: ${address ?? "N/A"}, '
      'estimateBaseFeeSat: ${estimateBaseFeeSat ?? "N/A"}, '
      'estimateProportionalFee: ${estimateProportionalFee ?? "N/A"}, '
      'isLoading: $isLoading, '
      'error: ${error ?? "N/A"}, '
      'paymentsWaitingCount: ${paymentsWaitingFeeAcceptance.length}, '
      'proposedFeesCount: ${proposedFeesMap.length}, '
      'isLoadingPayments: $isLoadingPayments, '
      'isReviewingFees: $isReviewingFees'
      ')';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is AmountlessBtcState &&
        other.address == address &&
        other.estimateBaseFeeSat == estimateBaseFeeSat &&
        other.estimateProportionalFee == estimateProportionalFee &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.paymentsWaitingFeeAcceptance == paymentsWaitingFeeAcceptance &&
        other.proposedFeesMap == proposedFeesMap &&
        other.isLoadingPayments == isLoadingPayments &&
        other.isReviewingFees == isReviewingFees;
  }

  @override
  int get hashCode => Object.hash(
    address,
    estimateBaseFeeSat,
    estimateProportionalFee,
    isLoading,
    error,
    paymentsWaitingFeeAcceptance,
    proposedFeesMap,
    isLoadingPayments,
    isReviewingFees,
  );
}
