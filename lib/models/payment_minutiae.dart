import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

// TODO: Liquid - Remove if having PaymentMinutiae is not necessary with Liquid SDK
/// Hold formatted data from Payment to be displayed in the UI, using the minutiae noun instead of details or
/// info to avoid conflicts and make it easier to differentiate when reading the code.
class PaymentMinutiae {
  final String id;
  final String title;
  final String preimage;
  final String swapId;
  final PaymentType paymentType;
  final DateTime paymentTime;
  final int feeSat;
  final int amountSat;
  final PaymentState status;

  const PaymentMinutiae({
    required this.id,
    required this.title,
    required this.preimage,
    required this.swapId,
    required this.paymentType,
    required this.paymentTime,
    required this.feeSat,
    required this.amountSat,
    required this.status,
  });

  factory PaymentMinutiae.fromPayment(Payment payment, BreezTranslations texts) {
    final factory = _PaymentMinutiaeFactory(payment, texts);
    return PaymentMinutiae(
      id: payment.txId,
      title: factory._title(),
      preimage: payment.preimage ?? "",
      swapId: payment.swapId ?? "",
      paymentType: payment.paymentType,
      paymentTime: factory._paymentTime(),
      feeSat: payment.feesSat?.toInt() ?? 0,
      amountSat: payment.amountSat.toInt(),
      status: payment.status,
    );
  }
}

class _PaymentMinutiaeFactory {
  final Payment _payment;
  final BreezTranslations _texts;

  _PaymentMinutiaeFactory(this._payment, this._texts);

  String _title() {
    return _texts.wallet_dashboard_payment_item_no_title;
  }

  DateTime _paymentTime() {
    return DateTime.fromMillisecondsSinceEpoch(_payment.timestamp * 1000);
  }
}
