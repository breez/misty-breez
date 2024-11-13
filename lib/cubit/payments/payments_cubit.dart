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

final _logger = Logger("PaymentsCubit");

class PaymentsCubit extends Cubit<PaymentsState> with HydratedMixin {
  static const String paymentFilterSettingsKey = "payment_filter_settings";

  final StreamController<PaymentFilters> _paymentFiltersStreamController = BehaviorSubject<PaymentFilters>();

  Stream<PaymentFilters> get paymentFiltersStream => _paymentFiltersStreamController.stream;

  final BreezSDKLiquid _breezSdkLiquid;

  PaymentsCubit(
    this._breezSdkLiquid,
  ) : super(PaymentsState.initial()) {
    hydrate();

    _paymentFiltersStreamController.add(state.paymentFilters);

    _listenPaymentChanges();
  }

  void _listenPaymentChanges() {
    _logger.info("_listenPaymentChanges\nListening to changes in payments");
    final texts = getSystemAppLocalizations();

    Rx.combineLatest2<List<Payment>, PaymentFilters, PaymentsState>(
      _breezSdkLiquid.paymentsStream,
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
    _logger.info("prepareSendPayment\nPreparing send payment for destination: $destination");
    try {
      // TODO: Handle the drain option for PrepareSendRequest
      final payAmount = amountSat != null ? PayAmount_Receiver(amountSat: amountSat) : null;
      final req = PrepareSendRequest(destination: destination, amount: payAmount);
      return await _breezSdkLiquid.instance!.prepareSendPayment(req: req);
    } catch (e) {
      _logger.severe("prepareSendPayment\nError preparing send payment", e);
      return Future.error(e);
    }
  }

  Future<SendPaymentResponse> sendPayment(PrepareSendResponse prepareResponse) async {
    _logger.info("sendPayment\nSending payment for $prepareResponse");
    try {
      final req = SendPaymentRequest(prepareResponse: prepareResponse);
      return await _breezSdkLiquid.instance!.sendPayment(req: req);
    } catch (e) {
      _logger.severe("sendPayment\nError sending payment", e);
      return Future.error(e);
    }
  }

  Future<PrepareReceiveResponse> prepareReceivePayment({
    required PaymentMethod paymentMethod,
    BigInt? payerAmountSat,
  }) async {
    _logger.info("prepareReceivePayment\nPreparing receive payment for $payerAmountSat sats");
    try {
      final req = PrepareReceiveRequest(
        paymentMethod: paymentMethod,
        payerAmountSat: payerAmountSat,
      );
      return _breezSdkLiquid.instance!.prepareReceivePayment(req: req);
    } catch (e) {
      _logger.severe("prepareSendPayment\nError preparing receive payment", e);
      return Future.error(e);
    }
  }

  Future<ReceivePaymentResponse> receivePayment({
    required PrepareReceiveResponse prepareResponse,
    String? description,
  }) async {
    _logger.info(
      "receivePayment\nReceive ${prepareResponse.paymentMethod.name} payment for amount: "
      "${prepareResponse.payerAmountSat} (sats), fees: ${prepareResponse.feesSat} (sats), description: $description",
    );
    try {
      final req = ReceivePaymentRequest(prepareResponse: prepareResponse, description: description);
      return _breezSdkLiquid.instance!.receivePayment(req: req);
    } catch (e) {
      _logger.severe("receivePayment\nError receiving payment", e);
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
    _logger.info("changePaymentFilter\nChanging payment filter: $newPaymentFilters");
    _paymentFiltersStreamController.add(newPaymentFilters);
  }

  // TODO: Liquid SDK - Canceling payments are not yet supported
  Future cancelPayment(String invoice) async {
    _logger.info("cancelPayment\nCanceling payment for invoice: $invoice");
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
