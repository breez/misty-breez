import 'dart:convert';

import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/utils/utils.dart';

final Logger _logger = Logger('PaymentData');

/// Holds formatted payment data for UI display
class PaymentData {
  final String id;
  final String title;
  final String description;
  final String destination;
  final String txId;
  final String unblindingData;
  final DateTime paymentTime;
  final int amountSat;
  final int feeSat;
  final PaymentType paymentType;
  final PaymentState status;
  final PaymentDetails details;

  const PaymentData({
    required this.id,
    required this.title,
    required this.description,
    required this.destination,
    required this.txId,
    required this.unblindingData,
    required this.paymentTime,
    required this.amountSat,
    required this.feeSat,
    required this.paymentType,
    required this.status,
    required this.details,
  });

  factory PaymentData.fromPayment(Payment payment, BreezTranslations texts) {
    final _PaymentDataFactory factory = _PaymentDataFactory(payment, texts);

    return PaymentData(
      id: payment.txId ?? '',
      title: factory._title(),
      description: factory._description(),
      destination: payment.destination ?? '',
      txId: payment.txId ?? '',
      unblindingData: payment.unblindingData ?? '',
      paymentTime: factory._paymentTime(),
      amountSat: payment.amountSat.toInt(),
      feeSat: payment.feesSat.toInt(),
      paymentType: payment.paymentType,
      status: payment.status,
      details: payment.details,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'destination': destination,
      'txId': txId,
      'unblindingData': unblindingData,
      'paymentTime': paymentTime.toIso8601String(),
      'amountSat': amountSat,
      'feeSat': feeSat,
      'paymentType': paymentType.name,
      'status': status.name,
      'details': details.toJson(),
    };
  }

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    try {
      final PaymentType paymentType = parseEnum(
        value: json['paymentType'],
        enumValues: PaymentType.values,
        defaultValue: PaymentType.send,
      );

      final PaymentState status = parseEnum(
        value: json['status'],
        enumValues: PaymentState.values,
        defaultValue: PaymentState.pending,
      );

      return PaymentData(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        destination: json['destination'] as String? ?? '',
        txId: json['txId'] as String? ?? '',
        unblindingData: json['unblindingData'] as String? ?? '',
        paymentTime:
            json['paymentTime'] != null ? DateTime.parse(json['paymentTime'] as String) : DateTime.now(),
        amountSat: json['amountSat'] as int? ?? 0,
        feeSat: json['feeSat'] as int? ?? 0,
        paymentType: paymentType,
        status: status,
        details: PaymentDetailsFromJson.fromJson(
          json['details'] as Map<String, dynamic>? ?? <String, dynamic>{},
        ),
      );
    } catch (e) {
      _logger.warning('Error deserializing PaymentData: $e');
      throw FormatException('Failed to parse PaymentData: $e');
    }
  }

  @override
  String toString() => jsonEncode(toJson());

  @override
  int get hashCode => Object.hash(
        id,
        title,
        destination,
        txId,
        unblindingData,
        paymentTime,
        amountSat,
        feeSat,
        paymentType,
        status,
        details.calculateHashCode(),
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PaymentData &&
            id == other.id &&
            title == other.title &&
            destination == other.destination &&
            txId == other.txId &&
            unblindingData == other.unblindingData &&
            paymentTime == other.paymentTime &&
            paymentType == other.paymentType &&
            amountSat == other.amountSat &&
            feeSat == other.feeSat &&
            status == other.status &&
            details.equals(other.details);
  }

  int get refundTxAmountSat => details.map(
        bitcoin: (PaymentDetails_Bitcoin details) => details.refundTxAmountSat?.toInt() ?? 0,
        lightning: (PaymentDetails_Lightning details) => details.refundTxAmountSat?.toInt() ?? 0,
        orElse: () => 0,
      );

  String? get refundTxId => details.map(
        bitcoin: (PaymentDetails_Bitcoin details) => details.refundTxId,
        lightning: (PaymentDetails_Lightning details) => details.refundTxId,
        orElse: () => null,
      );

  bool get isRefunded => (refundTxAmountSat > 0 || refundTxId != null) && status == PaymentState.failed;

  int get actualFeeSat => (isRefunded && refundTxAmountSat > 0) ? amountSat - refundTxAmountSat : feeSat;

  String? get lnurlMetadataImage {
    final Map<String, dynamic> metadataMap = getLnurlPayMetadata(details);
    return metadataMap['image/png;base64'] ?? metadataMap['image/jpeg;base64'];
  }
}

class _PaymentDataFactory {
  final Payment _payment;
  final BreezTranslations _texts;

  _PaymentDataFactory(this._payment, this._texts);

  String _title() {
    final String? bip353Address = _payment.details.map(
      lightning: (PaymentDetails_Lightning details) => details.bip353Address,
      liquid: (PaymentDetails_Liquid details) => details.bip353Address,
      orElse: () => null,
    );

    if (bip353Address?.isNotEmpty == true) {
      return bip353Address!;
    }

    final LnUrlInfo? lnurlInfo = _payment.details.map(
      lightning: (PaymentDetails_Lightning details) => details.lnurlInfo,
      liquid: (PaymentDetails_Liquid details) => details.lnurlInfo,
      orElse: () => null,
    );

    if (lnurlInfo != null) {
      final Map<String, dynamic> metadataMap = getLnurlPayMetadata(_payment.details);
      final String? lnUrlTitle = lnurlInfo.lnAddress?.isNotEmpty == true
          ? lnurlInfo.lnAddress
          : metadataMap['text/identifier'] ??
              metadataMap['text/email'] ??
              (lnurlInfo.lnurlPayDomain?.isNotEmpty == true ? lnurlInfo.lnurlPayDomain : null);

      if (lnUrlTitle != null && lnUrlTitle.isNotEmpty) {
        return lnUrlTitle;
      }
    }

    final String description = _description();
    if (description.isNotEmpty && !description.isDefaultDescription) {
      return description;
    }

    return _texts.payment_info_title_unknown;
  }

  String _description() {
    return _getLnurlDescription() ?? _getDescriptionFromDetails() ?? '';
  }

  String? _getDescriptionFromDetails() {
    return _payment.details.map(
      lightning: (PaymentDetails_Lightning details) => details.description,
      bitcoin: (PaymentDetails_Bitcoin details) => details.description,
      liquid: (PaymentDetails_Liquid details) => details.description,
      orElse: () => null,
    );
  }

  String? _getLnurlDescription() {
    final Map<String, dynamic> metadataMap = getLnurlPayMetadata(_payment.details);
    return metadataMap['text/long-desc'] ?? metadataMap['text/plain'];
  }

  DateTime _paymentTime() {
    return DateTime.fromMillisecondsSinceEpoch(_payment.timestamp * 1000);
  }
}

Map<String, dynamic> getLnurlPayMetadata(PaymentDetails details) {
  final String? lnurlPayMetadata = details.map(
    lightning: (PaymentDetails_Lightning details) => details.lnurlInfo?.lnurlPayMetadata,
    orElse: () => null,
  );

  return _parseLnurlPayMetadata(lnurlPayMetadata);
}

Map<String, dynamic> _parseLnurlPayMetadata(String? lnurlPayMetadata) {
  if (lnurlPayMetadata == null) {
    return <String, dynamic>{};
  }

  try {
    final dynamic decoded = json.decode(lnurlPayMetadata);
    if (decoded is! List) {
      return <String, dynamic>{};
    }

    return Map<String, dynamic>.fromEntries(
      decoded
          .whereType<List<dynamic>>()
          .where((List<dynamic> item) => item.length == 2 && item[0] is String)
          .map((List<dynamic> item) => MapEntry<String, dynamic>(item[0] as String, item[1])),
    );
  } catch (_) {
    return <String, dynamic>{};
  }
}
