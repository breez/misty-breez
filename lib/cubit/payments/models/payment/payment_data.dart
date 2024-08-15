import 'dart:convert';

import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

// TODO: Liquid - Remove if having PaymentData is not necessary with Liquid SDK
/// Hold formatted data from Payment to be displayed in the UI, using the minutiae noun instead of details or
/// info to avoid conflicts and make it easier to differentiate when reading the code.
class PaymentData {
  final String id;
  final String title;
  final String description;
  final String preimage;
  final String bolt11;
  final String swapId;
  final String txId;
  final String refundTxId;
  final PaymentType paymentType;
  final DateTime paymentTime;
  final int feeSat;
  final int amountSat;
  final int refundTxAmountSat;
  final PaymentState status;

  const PaymentData({
    required this.id,
    required this.title,
    required this.description,
    required this.preimage,
    required this.bolt11,
    required this.swapId,
    required this.txId,
    required this.refundTxId,
    required this.paymentType,
    required this.paymentTime,
    required this.feeSat,
    required this.amountSat,
    required this.refundTxAmountSat,
    required this.status,
  });

  factory PaymentData.fromPayment(Payment payment, BreezTranslations texts) {
    final factory = _PaymentDataFactory(payment, texts);

    return PaymentData(
      id: payment.txId ?? "",
      title: factory._title(),
      description: payment.description,
      preimage: payment.preimage ?? "",
      bolt11: payment.bolt11 ?? "",
      swapId: payment.swapId ?? "",
      txId: payment.txId ?? "",
      refundTxId: payment.refundTxId ?? "",
      paymentType: payment.paymentType,
      paymentTime: factory._paymentTime(),
      feeSat: payment.feesSat.toInt(),
      amountSat: payment.amountSat.toInt(),
      refundTxAmountSat: payment.refundTxAmountSat?.toInt() ?? 0,
      status: payment.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'preimage': preimage,
      'bolt11': bolt11,
      'swapId': swapId,
      'txId': txId,
      'refundTxId': refundTxId,
      'paymentType': paymentType.name,
      'paymentTime': paymentTime.toIso8601String(),
      'feeSat': feeSat,
      'amountSat': amountSat,
      'refundTxAmountSat': refundTxAmountSat,
      'status': status.name,
    };
  }

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        preimage: json['preimage'],
        bolt11: json['bolt11'],
        swapId: json['swapId'],
        txId: json['txId'],
        refundTxId: json['refundTxId'],
        paymentType: PaymentType.values.byName(json['paymentType']),
        paymentTime: DateTime.parse(json['paymentTime']),
        feeSat: json['feeSat'],
        amountSat: json['amountSat'],
        refundTxAmountSat: json['refundTxAmountSat'],
        status: PaymentState.values.byName(json['status']));
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
    if (_payment.description.isNotEmpty) return _payment.description;
    return title;
  }

  DateTime _paymentTime() {
    return DateTime.fromMillisecondsSinceEpoch(_payment.timestamp * 1000);
  }
}
