import 'dart:convert';

import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/models/payment_details_extension.dart';

// TODO(erdemyerebasmaz): Liquid - Remove if having PaymentData is not necessary with Liquid SDK
/// Hold formatted data from Payment to be displayed in the UI, using the minutiae noun instead of details or
/// info to avoid conflicts and make it easier to differentiate when reading the code.
class PaymentData {
  final String id;
  final String title;
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
    return PaymentData(
      id: json['id'],
      title: json['title'],
      destination: json['destination'],
      txId: json['txId'],
      unblindingData: json['unblindingData'],
      paymentTime: DateTime.parse(json['paymentTime']),
      amountSat: json['amountSat'],
      feeSat: json['feeSat'],
      paymentType: PaymentType.values.byName(json['paymentType']),
      status: PaymentState.values.byName(json['status']),
      details: PaymentDetailsFromJson.fromJson(json['details']),
    );
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

  bool get isRefunded {
    final int refundTxAmountSat = details.map(
      bitcoin: (PaymentDetails_Bitcoin details) => details.refundTxAmountSat?.toInt() ?? 0,
      lightning: (PaymentDetails_Lightning details) => details.refundTxAmountSat?.toInt() ?? 0,
      orElse: () => 0,
    );
    return refundTxAmountSat > 0 && status == PaymentState.failed;
  }
}

class _PaymentDataFactory {
  final Payment _payment;
  final BreezTranslations _texts;

  _PaymentDataFactory(this._payment, this._texts);

  String _title() {
    final String title = _texts.payment_info_title_unknown;
    final String description = _payment.details.map(
      lightning: (PaymentDetails_Lightning details) => details.description,
      bitcoin: (PaymentDetails_Bitcoin details) => details.description,
      liquid: (PaymentDetails_Liquid details) => details.description,
      orElse: () => '',
    );
    if (description.isNotEmpty) {
      return description;
    }
    return title;
  }

  DateTime _paymentTime() {
    return DateTime.fromMillisecondsSinceEpoch(_payment.timestamp * 1000);
  }
}
