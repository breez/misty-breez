library payment_cubit;

import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/payments/models/models.dart';
import 'package:l_breez/cubit/payments/payments_state.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

export 'models/models.dart';
export 'payments_state.dart';

final _log = Logger("PaymentsCubit");

class PaymentsCubit extends Cubit<PaymentsState> with HydratedMixin {
  static const String paymentFilterSettingsKey = "payment_filter_settings";

  final StreamController<PaymentFilters> _paymentFiltersStreamController = BehaviorSubject<PaymentFilters>();

  Stream<PaymentFilters> get paymentFiltersStream => _paymentFiltersStreamController.stream;

  final BreezSDKLiquid _liquidSdk;

  PaymentsCubit(
    this._liquidSdk,
  ) : super(PaymentsState.initial()) {
    hydrate();

    _paymentFiltersStreamController.add(state.paymentFilters);

    _listenPaymentChanges();
  }

  void _listenPaymentChanges() {
    _log.info("_listenPaymentChanges\nListening to changes in payments");
    final texts = getSystemAppLocalizations();

    Rx.combineLatest2<List<Payment>, PaymentFilters, PaymentsState>(
      _liquidSdk.paymentsStream,
      paymentFiltersStream,
      (payments, paymentFilters) {
        return state.copyWith(
          payments: payments.map((e) => PaymentData.fromPayment(e, texts)).toList(),
          paymentFilters: paymentFilters,
        );
      },
    ).distinct().listen((newState) => emit(newState));
  }

  Future<PrepareSendResponse> prepareSendPayment(String invoice) async {
    _log.info("prepareSendPayment\nPreparing send payment for invoice: $invoice");
    try {
      final req = PrepareSendRequest(invoice: invoice);
      return await _liquidSdk.instance!.prepareSendPayment(req: req);
    } catch (e) {
      _log.severe("prepareSendPayment\nError preparing send payment", e);
      return Future.error(e);
    }
  }

  Future<SendPaymentResponse> sendPayment(PrepareSendResponse req) async {
    _log.info("sendPayment\nSending payment for $req");
    try {
      return await _liquidSdk.instance!.sendPayment(req: req);
    } catch (e) {
      _log.severe("sendPayment\nError sending payment", e);
      return Future.error(e);
    }
  }

  Future<PrepareReceivePaymentResponse> prepareReceivePayment(int payerAmountSat) async {
    _log.info("prepareReceivePayment\nPreparing receive payment for $payerAmountSat sats");
    try {
      final req = PrepareReceivePaymentRequest(payerAmountSat: BigInt.from(payerAmountSat));
      return _liquidSdk.instance!.prepareReceivePayment(req: req);
    } catch (e) {
      _log.severe("prepareSendPayment\nError preparing receive payment", e);
      return Future.error(e);
    }
  }

  Future<ReceivePaymentResponse> receivePayment(ReceivePaymentRequest req) async {
    _log.info(
      "receivePayment\nReceive payment for amount: ${req.prepareRes.payerAmountSat} (sats), fees: ${req.prepareRes.feesSat} (sats), description: ${req.description}",
    );
    try {
      return _liquidSdk.instance!.receivePayment(req: req);
    } catch (e) {
      _log.severe("receivePayment\nError receiving payment", e);
      return Future.error(e);
    }
  }

  void changePaymentFilter({
    List<PaymentType>? filters,
    int? fromTimestamp,
    int? toTimestamp,
  }) async {
    final newPaymentFilters = state.paymentFilters.copyWith(
      filters: filters,
      fromTimestamp: fromTimestamp,
      toTimestamp: toTimestamp,
    );
    _log.info("changePaymentFilter\nChanging payment filter: $newPaymentFilters");
    _paymentFiltersStreamController.add(newPaymentFilters);
  }

  // TODO: Liquid SDK - Canceling payments are not yet supported
  Future cancelPayment(String invoice) async {
    _log.info("cancelPayment\nCanceling payment for invoice: $invoice");
    throw Exception("Canceling payments are not yet supported");
  }

  @override
  PaymentsState? fromJson(Map<String, dynamic> json) {
    return PaymentsState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(PaymentsState state) {
    return state.toJson();
  }
}
