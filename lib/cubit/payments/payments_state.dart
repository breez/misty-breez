import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:l_breez/cubit/payments/models/models.dart';

class PaymentsState {
  final List<PaymentData> payments;
  final PaymentFilters paymentFilters;

  const PaymentsState({required this.payments, required this.paymentFilters});

  PaymentsState.initial() : this(payments: [], paymentFilters: PaymentFilters.initial());

  PaymentsState copyWith({
    List<PaymentData>? payments,
    PaymentFilters? paymentFilters,
  }) {
    return PaymentsState(
      payments: payments ?? this.payments,
      paymentFilters: paymentFilters ?? this.paymentFilters,
    );
  }

  List<PaymentData> get filteredPayments {
    if (paymentFilters == PaymentFilters.initial()) return payments;

    final typeFilterSet =
        paymentFilters.hasTypeFilters ? paymentFilters.filters!.map((filter) => filter.name).toSet() : null;

    return payments.where(
      (paymentData) {
        final milliseconds = paymentData.paymentTime.millisecondsSinceEpoch;

        final passDateFilter = !paymentFilters.hasDateFilters ||
            (paymentFilters.fromTimestamp! < milliseconds && milliseconds < paymentFilters.toTimestamp!);

        final passTypeFilter = typeFilterSet == null || typeFilterSet.contains(paymentData.paymentType.name);

        return passDateFilter && passTypeFilter;
      },
    ).toList();
  }

  Map<String, dynamic>? toJson() {
    return {
      "payments": payments.map((payment) => payment.toJson()).toList(),
      "paymentFilters": paymentFilters.toJson(),
    };
  }

  factory PaymentsState.fromJson(Map<String, dynamic> json) {
    return PaymentsState(
      payments: json['payments'].map((paymentJson) => PaymentData.fromJson(paymentJson)).toList(),
      paymentFilters: PaymentFilters.fromJson(json["paymentFilters"]),
    );
  }

  @override
  String toString() => jsonEncode(toJson());

  @override
  int get hashCode => Object.hash(
        payments.map((payment) => payment.hashCode).toList(),
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
