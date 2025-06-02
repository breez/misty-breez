import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('PaymentFilters');

class PaymentFilters implements Exception {
  final List<PaymentType>? filters;
  final int? fromTimestamp;
  final int? toTimestamp;
  final String? assetTicker;

  PaymentFilters({this.filters = PaymentType.values, this.fromTimestamp, this.toTimestamp, this.assetTicker});

  PaymentFilters.initial() : this();

  bool get hasTypeFilters => filters != null && !listEquals(filters, (PaymentType.values));

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

  factory PaymentFilters.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return PaymentFilters.initial();
    }

    try {
      List<PaymentType>? paymentFilters;
      final dynamic filtersValue = json['filters'];

      if (filtersValue is List) {
        paymentFilters = <PaymentType>[];
        for (final dynamic filter in filtersValue) {
          if (filter is String) {
            // Handle both formats: "PaymentType.receive" or just "receive"
            final String enumValue = filter.contains('.') ? filter.split('.').last : filter;

            try {
              final PaymentType paymentType = PaymentType.values.firstWhere(
                (PaymentType type) => type.name == enumValue,
                orElse: () => throw Exception('Invalid PaymentType: $filter'),
              );
              paymentFilters.add(paymentType);
            } catch (e) {
              _logger.warning('Error parsing PaymentType: $filter - $e');
            }
          }
        }
      }

      return PaymentFilters(
        filters: paymentFilters ?? PaymentType.values,
        fromTimestamp: json['fromTimestamp'],
        toTimestamp: json['toTimestamp'],
        assetTicker: json['assetTicker'],
      );
    } catch (e) {
      _logger.warning('Error deserializing PaymentFilters: $e');
      return PaymentFilters.initial();
    }
  }

  Map<String, dynamic> toJson() {
    final List<String>? filtersJson = filters?.map((PaymentType type) => type.name).toList();

    return <String, dynamic>{
      'filters': filtersJson,
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
