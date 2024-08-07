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

  Future<PrepareSendResponse> prepareSendPayment({
    required String destination,
    BigInt? amountSat,
  }) async {
    _log.info("prepareSendPayment\nPreparing send payment for destination: $destination");
    try {
      final req = PrepareSendRequest(destination: destination, amountSat: amountSat);
      return await _liquidSdk.instance!.prepareSendPayment(req: req);
    } catch (e) {
      _log.severe("prepareSendPayment\nError preparing send payment", e);
      return Future.error(e);
    }
  }

  Future<SendPaymentResponse> sendPayment(PrepareSendResponse prepareResponse) async {
    _log.info("sendPayment\nSending payment for $prepareResponse");
    try {
      final req = SendPaymentRequest(prepareResponse: prepareResponse);
      return await _liquidSdk.instance!.sendPayment(req: req);
    } catch (e) {
      _log.severe("sendPayment\nError sending payment", e);
      return Future.error(e);
    }
  }

  Future<PrepareReceiveResponse> prepareReceivePayment({
    required PaymentMethod paymentMethod,
    BigInt? amountSat,
  }) async {
    _log.info("prepareReceivePayment\nPreparing receive payment for $amountSat sats");
    try {
      final req = PrepareReceiveRequest(
        paymentMethod: paymentMethod,
        amountSat: amountSat,
      );
      return _liquidSdk.instance!.prepareReceivePayment(req: req);
    } catch (e) {
      _log.severe("prepareSendPayment\nError preparing receive payment", e);
      return Future.error(e);
    }
  }

  Future<ReceivePaymentResponse> receivePayment({
    required PrepareReceiveResponse prepareResponse,
    String? description,
  }) async {
    _log.info(
      "receivePayment\nReceive ${prepareResponse.paymentMethod.name} payment for amount: "
      "${prepareResponse.amountSat} (sats), fees: ${prepareResponse.feesSat} (sats), description: $description",
    );
    try {
      final req = ReceivePaymentRequest(prepareResponse: prepareResponse, description: description);
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
