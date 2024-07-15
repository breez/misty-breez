import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

// TODO: Liquid - Remove if having PaymentMinutiae is not necessary with Liquid SDK
/// Hold formatted data from Payment to be displayed in the UI, using the minutiae noun instead of details or
/// info to avoid conflicts and make it easier to differentiate when reading the code.
class PaymentMinutiae {
  final String id;
  final String title;
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

  const PaymentMinutiae({
    required this.id,
    required this.title,
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

  factory PaymentMinutiae.fromPayment(Payment payment, BreezTranslations texts) {
    final factory = _PaymentMinutiaeFactory(payment, texts);

    return PaymentMinutiae(
      id: payment.txId ?? "",
      title: factory._title(),
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
}

class _PaymentMinutiaeFactory {
  final Payment _payment;
  final BreezTranslations _texts;

  _PaymentMinutiaeFactory(this._payment, this._texts);

  String _title() {
    var title = "${_texts.wallet_dashboard_payment_item_no_title} Payment";
    if (_payment.bolt11 != null) return "Lightning Payment";
    if (_payment.refundTxId != null) return "Refund Transaction";
    if (_payment.swapId != null) return "Chain Swap Transaction";
    return title;
  }

  DateTime _paymentTime() {
    return DateTime.fromMillisecondsSinceEpoch(_payment.timestamp * 1000);
  }
}
