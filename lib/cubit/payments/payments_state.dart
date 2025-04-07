import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';

class PaymentsState {
  final List<PaymentData> payments;
  final PaymentFilters paymentFilters;

  const PaymentsState({required this.payments, required this.paymentFilters});

  PaymentsState.initial() : this(payments: <PaymentData>[], paymentFilters: PaymentFilters.initial());

  PaymentsState copyWith({
    List<PaymentData>? payments,
    PaymentFilters? paymentFilters,
  }) {
    // This is a workaround to only include BTC assets in the unfiltered payments.
    // If Misty is to support multi-assets then this prefilter should be removed.
    final List<PaymentData>? prefilteredPayments = payments?.where((PaymentData paymentData) {
      final String? paymentAssetTicker = paymentData.details.map(
        liquid: (PaymentDetails_Liquid details) => details.assetInfo?.ticker ?? '',
        orElse: () => null,
      );
      return paymentAssetTicker == null || paymentAssetTicker == 'BTC';
    }).toList();

    return PaymentsState(
      payments: prefilteredPayments ?? this.payments,
      paymentFilters: paymentFilters ?? this.paymentFilters,
    );
  }

  List<PaymentData> get filteredPayments {
    if (paymentFilters == PaymentFilters.initial()) {
      return payments;
    }

    final Set<String>? typeFilterSet = paymentFilters.hasTypeFilters
        ? paymentFilters.filters!.map((PaymentType filter) => filter.name).toSet()
        : null;

    return payments.where(
      (PaymentData paymentData) {
        final int milliseconds = paymentData.paymentTime.millisecondsSinceEpoch;

        final bool passDateFilter = !paymentFilters.hasDateFilters ||
            (paymentFilters.fromTimestamp! < milliseconds && milliseconds < paymentFilters.toTimestamp!);

        final bool passTypeFilter =
            typeFilterSet == null || typeFilterSet.contains(paymentData.paymentType.name);

        final String? paymentAssetTicker = paymentData.details.map(
          liquid: (PaymentDetails_Liquid details) => details.assetInfo?.ticker ?? '',
          orElse: () => null,
        );

        final bool passAssetFilter = !paymentFilters.hasAssetFilters ||
            paymentAssetTicker == null ||
            paymentAssetTicker == paymentFilters.assetTicker;

        return passDateFilter && passTypeFilter && passAssetFilter;
      },
    ).toList();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'payments': payments.map((PaymentData payment) => payment.toJson()).toList(),
      'paymentFilters': paymentFilters.toJson(),
    };
  }

  factory PaymentsState.fromJson(Map<String, dynamic> json) {
    return PaymentsState(
      payments: (json['payments'] as List<dynamic>? ?? <PaymentData>[])
          .map((dynamic paymentJson) => PaymentData.fromJson(paymentJson))
          .toList(),
      paymentFilters: PaymentFilters.fromJson(json['paymentFilters']),
    );
  }

  @override
  String toString() => jsonEncode(toJson());

  @override
  int get hashCode => Object.hash(
        payments.map((PaymentData payment) => payment.hashCode).toList(),
        paymentFilters.hashCode,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PaymentsState &&
            listEquals(payments, other.payments) &&
            paymentFilters == other.paymentFilters;
  }
}
