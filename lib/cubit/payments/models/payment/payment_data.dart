import 'dart:convert';

import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/models/payment_details_extension.dart';

// TODO: Liquid - Remove if having PaymentData is not necessary with Liquid SDK
/// Hold formatted data from Payment to be displayed in the UI, using the minutiae noun instead of details or
/// info to avoid conflicts and make it easier to differentiate when reading the code.
class PaymentData {
  final String id;
  final String title;
  final String destination;
  final String txId;
  final DateTime paymentTime;
  final int amountSat;
  final int feeSat;
  final PaymentType paymentType;
  final PaymentState status;
  final PaymentDetails? details;

  const PaymentData({
    required this.id,
    required this.title,
    required this.destination,
    required this.txId,
    required this.paymentTime,
    required this.amountSat,
    required this.feeSat,
    required this.paymentType,
    required this.status,
    this.details,
  });

  factory PaymentData.fromPayment(Payment payment, BreezTranslations texts) {
    final factory = _PaymentDataFactory(payment, texts);

    return PaymentData(
      id: payment.txId ?? "",
      title: factory._title(),
      destination: payment.destination ?? "",
      txId: payment.txId ?? "",
      paymentTime: factory._paymentTime(),
      amountSat: payment.amountSat.toInt(),
      feeSat: payment.feesSat.toInt(),
      paymentType: payment.paymentType,
      status: payment.status,
      details: payment.details,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'destination': destination,
      'txId': txId,
      'paymentTime': paymentTime.toIso8601String(),
      'amountSat': amountSat,
      'feeSat': feeSat,
      'paymentType': paymentType.name,
      'status': status.name,
      // TODO: Deserialize PaymentDetails
      'details': details,
    };
  }

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      id: json['id'],
      title: json['title'],
      destination: json['destination'],
      txId: json['txId'],
      paymentTime: DateTime.parse(json['paymentTime']),
      amountSat: json['amountSat'],
      feeSat: json['feeSat'],
      paymentType: PaymentType.values.byName(json['paymentType']),
      status: PaymentState.values.byName(json['status']),
      // TODO: Serialize PaymentDetails
      details: json['details'],
    );
  }

  @override
  String toString() => jsonEncode(toJson());

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        preimage,
        bolt11,
        swapId,
        txId,
        refundTxId,
        paymentType,
        paymentTime,
        feeSat,
        amountSat,
        refundTxAmountSat,
        status,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PaymentData &&
            id == other.id &&
            title == other.title &&
            description == other.description &&
            preimage == other.preimage &&
            bolt11 == other.bolt11 &&
            swapId == other.swapId &&
            txId == other.txId &&
            refundTxId == other.refundTxId &&
            paymentType == other.paymentType &&
            paymentTime == other.paymentTime &&
            feeSat == other.feeSat &&
            amountSat == other.amountSat &&
            refundTxAmountSat == other.refundTxAmountSat &&
            status == other.status;
  }
}

class _PaymentDataFactory {
  final Payment _payment;
  final BreezTranslations _texts;

  _PaymentDataFactory(this._payment, this._texts);

  String _title() {
    var title = "${_texts.wallet_dashboard_payment_item_no_title} Payment";
    final description = _payment.details?.maybeMap(
          lightning: (details) => details.description,
          bitcoin: (details) => details.description,
          liquid: (details) => details.description,
          orElse: () => "",
        ) ??
        "";
    if (description.isNotEmpty) return description;
    return title;
  }

  DateTime _paymentTime() {
    return DateTime.fromMillisecondsSinceEpoch(_payment.timestamp * 1000);
  }
}
