import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

class PaymentFilters implements Exception {
  final List<PaymentType>? filters;
  final int? fromTimestamp;
  final int? toTimestamp;
  final String? assetTicker;

  PaymentFilters({
    this.filters = PaymentType.values,
    this.fromTimestamp,
    this.toTimestamp,
    this.assetTicker,
  });

  PaymentFilters.initial() : this();

  bool get hasTypeFilters => filters != null && filters != PaymentType.values;

  bool get hasDateFilters => fromTimestamp != null || toTimestamp != null;

  bool get hasAssetFilters => assetTicker != null;

  PaymentFilters copyWith({
    List<PaymentType>? filters,
    int? fromTimestamp,
    int? toTimestamp,
    String? assetTicker,
  }) {
    return PaymentFilters(
      filters: filters ?? this.filters,
      fromTimestamp: fromTimestamp,
      toTimestamp: toTimestamp,
      assetTicker: assetTicker,
    );
  }

  factory PaymentFilters.fromJson(Map<String, dynamic> json) {
    return PaymentFilters(
      fromTimestamp: json['fromTimestamp'],
      toTimestamp: json['toTimestamp'],
      assetTicker: json['assetTicker'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'filters': filters.toString(),
      'fromTimestamp': fromTimestamp,
      'toTimestamp': toTimestamp,
      'assetTicker': assetTicker,
    };
  }

  @override
  String toString() => jsonEncode(toJson());

  @override
  int get hashCode => Object.hash(
        filters?.map((PaymentType type) => type.hashCode).toList() ?? <dynamic>[],
        fromTimestamp,
        toTimestamp,
        assetTicker,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PaymentFilters &&
            listEquals(filters, other.filters) &&
            fromTimestamp == other.fromTimestamp &&
            toTimestamp == other.toTimestamp &&
            assetTicker == other.assetTicker;
  }
}
