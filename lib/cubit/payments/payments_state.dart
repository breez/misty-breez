import 'dart:convert';

import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
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
    List<PaymentData> filteredPayments = payments;
    // Apply date filters, if there's any
    if (paymentFilters.fromTimestamp != null || paymentFilters.toTimestamp != null) {
      filteredPayments = payments.where((paymentData) {
        final fromTimestamp = paymentFilters.fromTimestamp;
        final toTimestamp = paymentFilters.toTimestamp;
        final milliseconds = paymentData.paymentTime.millisecondsSinceEpoch;
        if (fromTimestamp != null && toTimestamp != null) {
          return fromTimestamp < milliseconds && milliseconds < toTimestamp;
        }
        return true;
      }).toList();
    }

    // Apply payment type filters, if there's any
    final paymentTypeFilters = paymentFilters.filters;
    if (paymentTypeFilters != null && paymentTypeFilters != PaymentType.values) {
      filteredPayments = filteredPayments.where((paymentData) {
        return paymentTypeFilters.any(
          (filter) {
            return filter.name == paymentData.paymentType.name;
          },
        );
      }).toList();
    }
    return filteredPayments;
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
}
