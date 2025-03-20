import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

export 'models/models.dart';
export 'payments_state.dart';

final Logger _logger = Logger('PaymentsCubit');

class PaymentsCubit extends Cubit<PaymentsState> with HydratedMixin<PaymentsState> {
  static const String paymentFilterSettingsKey = 'payment_filter_settings';

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
    _logger.info('_listenPaymentChanges\nListening to changes in payments');
    final BreezTranslations texts = getSystemAppLocalizations();

    Rx.combineLatest2<List<Payment>, PaymentFilters, PaymentsState>(
      _breezSdkLiquid.paymentsStream,
      paymentFiltersStream,
      (List<Payment> payments, PaymentFilters paymentFilters) {
        return state.copyWith(
          payments: payments.map((Payment e) => PaymentData.fromPayment(e, texts)).toList(),
          paymentFilters: paymentFilters,
        );
      },
    ).distinct().listen((PaymentsState newState) => emit(newState));
  }

  Future<PrepareSendResponse> prepareSendPayment({
    required String destination,
    BigInt? amountSat,
  }) async {
    _logger.info('prepareSendPayment\nPreparing send payment for destination: $destination');
    try {
      // TODO(erdemyerebasmaz): Handle the drain option for PrepareSendRequest
      final PayAmount_Bitcoin? payAmount =
          amountSat != null ? PayAmount_Bitcoin(receiverAmountSat: amountSat) : null;
      final PrepareSendRequest req = PrepareSendRequest(destination: destination, amount: payAmount);
      return await _breezSdkLiquid.instance!.prepareSendPayment(req: req);
    } catch (e) {
      _logger.severe('prepareSendPayment\nError preparing send payment', e);
      return Future<PrepareSendResponse>.error(e);
    }
  }

  Future<SendPaymentResponse> sendPayment(PrepareSendResponse prepareResponse) async {
    _logger.info('sendPayment\nSending payment for $prepareResponse');
    try {
      final SendPaymentRequest req = SendPaymentRequest(prepareResponse: prepareResponse);
      return await _breezSdkLiquid.instance!.sendPayment(req: req);
    } catch (e) {
      _logger.severe('sendPayment\nError sending payment', e);
      return Future<SendPaymentResponse>.error(e);
    }
  }

  Future<PrepareReceiveResponse> prepareReceivePayment({
    required PaymentMethod paymentMethod,
    BigInt? payerAmountSat,
  }) async {
    _logger.info('prepareReceivePayment\nPreparing receive payment for $payerAmountSat sats');
    try {
      final ReceiveAmount_Bitcoin? receiveAmount =
          payerAmountSat != null ? ReceiveAmount_Bitcoin(payerAmountSat: payerAmountSat) : null;
      final PrepareReceiveRequest req = PrepareReceiveRequest(
        paymentMethod: paymentMethod,
        amount: receiveAmount,
      );
      return _breezSdkLiquid.instance!.prepareReceivePayment(req: req);
    } catch (e) {
      _logger.severe('prepareSendPayment\nError preparing receive payment', e);
      return Future<PrepareReceiveResponse>.error(e);
    }
  }

  Future<ReceivePaymentResponse> receivePayment({
    required PrepareReceiveResponse prepareResponse,
    String? description,
  }) async {
    _logger.info(
      'receivePayment\nReceive ${prepareResponse.paymentMethod.name} payment for amount: '
      '${prepareResponse.amount} (sats), fees: ${prepareResponse.feesSat} (sats), description: $description',
    );
    try {
      final ReceivePaymentRequest req =
          ReceivePaymentRequest(prepareResponse: prepareResponse, description: description);
      return _breezSdkLiquid.instance!.receivePayment(req: req);
    } catch (e) {
      _logger.severe('receivePayment\nError receiving payment', e);
      return Future<ReceivePaymentResponse>.error(e);
    }
  }

  void changePaymentFilter({
    List<PaymentType>? filters,
    int? fromTimestamp,
    int? toTimestamp,
  }) async {
    final PaymentFilters newPaymentFilters = state.paymentFilters.copyWith(
      filters: filters,
      fromTimestamp: fromTimestamp,
      toTimestamp: toTimestamp,
    );
    _logger.info('changePaymentFilter\nChanging payment filter: $newPaymentFilters');
    _paymentFiltersStreamController.add(newPaymentFilters);
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
