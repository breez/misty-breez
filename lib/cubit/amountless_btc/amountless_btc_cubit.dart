import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';

export 'amountless_btc_state.dart';

final Logger _logger = Logger('AmountlessBtcCubit');

class AmountlessBtcCubit extends Cubit<AmountlessBtcState> {
  final BreezSDKLiquid _breezSdkLiquid;

  AmountlessBtcCubit(this._breezSdkLiquid) : super(AmountlessBtcState.initial());

  /// Generates a new amountless Bitcoin address
  Future<void> generateAmountlessAddress() async {
    try {
      _logger.info('Generating amountless BTC address');

      emit(state.copyWith(isLoading: true));

      final PrepareReceiveRequest prepareReq = const PrepareReceiveRequest(
        paymentMethod: PaymentMethod.bitcoinAddress,
      );
      final PrepareReceiveResponse prepareResp = await _breezSdkLiquid.instance!.prepareReceivePayment(
        req: prepareReq,
      );
      final ReceivePaymentRequest req = ReceivePaymentRequest(prepareResponse: prepareResp);
      final ReceivePaymentResponse resp = await _breezSdkLiquid.instance!.receivePayment(req: req);

      final String address = resp.destination;
      final int estimateBaseFeeSat = prepareResp.feesSat.toInt();
      final double? estimateProportionalFee = prepareResp.swapperFeerate;

      _logger.info(
        'Successfully generated amountless BTC address: $address, '
        'estimated base fees: $estimateBaseFeeSat sats, '
        'estimate proportional fees: $estimateProportionalFee%',
      );

      emit(
        AmountlessBtcState(
          address: address,
          estimateBaseFeeSat: estimateBaseFeeSat,
          estimateProportionalFee: estimateProportionalFee,
        ),
      );
    } catch (e) {
      _logger.severe('Failed to generate amountless BTC address', e);
      emit(AmountlessBtcState(error: e));
    }
  }

  /// Lists payments waiting for fee acceptance
  Future<void> loadPaymentsWaitingFeeAcceptance() async {
    try {
      _logger.info('Loading payments waiting for fee acceptance');

      emit(state.copyWith(isLoadingPayments: true));

      const ListPaymentsRequest request = ListPaymentsRequest(
        filters: <PaymentType>[PaymentType.receive],
        states: <PaymentState>[PaymentState.waitingFeeAcceptance],
      );

      final List<Payment> paymentsList = await _breezSdkLiquid.instance!.listPayments(req: request);

      _logger.info('Found ${paymentsList.length} payments waiting for fee acceptance');

      emit(state.copyWith(paymentsWaitingFeeAcceptance: paymentsList, isLoadingPayments: false));
    } catch (e) {
      _logger.severe('Failed to load payments waiting for fee acceptance', e);
      emit(state.copyWith(error: e, isLoadingPayments: false));
    }
  }

  /// Fetches payment proposed fees for a specific payment
  Future<void> fetchPaymentProposedFees(String swapId) async {
    try {
      _logger.info('Fetching payment proposed fees for swap ID: $swapId');

      emit(state.copyWith(isLoadingFees: true));

      final FetchPaymentProposedFeesRequest request = FetchPaymentProposedFeesRequest(swapId: swapId);

      final FetchPaymentProposedFeesResponse response = await _breezSdkLiquid.instance!
          .fetchPaymentProposedFees(req: request);

      _logger.info(
        'Successfully fetched payment proposed fees for $swapId: '
        'Payer amount: ${response.payerAmountSat} sat, '
        'Fees: ${response.feesSat} sat, '
        'Receiver amount: ${response.receiverAmountSat} sat',
      );

      final Map<String, FetchPaymentProposedFeesResponse> updatedProposedFeesMap =
          Map<String, FetchPaymentProposedFeesResponse>.from(state.proposedFeesMap);
      updatedProposedFeesMap[swapId] = response;

      emit(state.copyWith(proposedFeesMap: updatedProposedFeesMap, isLoadingFees: false));
    } catch (e) {
      _logger.severe('Failed to fetch payment proposed fees for $swapId', e);
      emit(state.copyWith(error: e, isLoadingFees: false));
    }
  }

  /// Accepts the payment proposed fees for a specific payment
  Future<void> acceptPaymentProposedFees(String swapId) async {
    final FetchPaymentProposedFeesResponse? proposedFees = state.proposedFeesMap[swapId];
    if (proposedFees == null) {
      _logger.warning('Cannot accept payment proposed fees for $swapId: no proposed fees available');
      emit(state.copyWith(error: 'No proposed fees available for swap ID $swapId'));
      return;
    }

    try {
      _logger.info('Accepting payment proposed fees for swap ID: $swapId');

      emit(state.copyWith(isLoading: true));

      final AcceptPaymentProposedFeesRequest request = AcceptPaymentProposedFeesRequest(
        response: proposedFees,
      );

      await _breezSdkLiquid.instance!.acceptPaymentProposedFees(req: request);

      _logger.info('Successfully accepted payment proposed fees for $swapId');

      // Remove the payment from waiting list and proposed fees map
      final List<Payment> updatedPayments = state.paymentsWaitingFeeAcceptance.where((Payment payment) {
        final String paymentSwapId = payment.details.maybeMap(
          bitcoin: (PaymentDetails_Bitcoin details) => details.swapId,
          lightning: (PaymentDetails_Lightning details) => details.swapId,
          orElse: () => '',
        );
        return paymentSwapId != swapId;
      }).toList();

      final Map<String, FetchPaymentProposedFeesResponse> updatedProposedFeesMap =
          Map<String, FetchPaymentProposedFeesResponse>.from(state.proposedFeesMap);
      updatedProposedFeesMap.remove(swapId);

      emit(
        state.copyWith(
          paymentsWaitingFeeAcceptance: updatedPayments,
          proposedFeesMap: updatedProposedFeesMap,
          isLoading: false,
        ),
      );
    } catch (e) {
      _logger.severe('Failed to accept payment proposed fees for $swapId', e);
      emit(state.copyWith(error: e, isLoading: false));
    }
  }

  /// Rejects the payment proposed fees for a specific payment
  void rejectPaymentProposedFees(String swapId) {
    _logger.info('Rejecting payment proposed fees for swap ID: $swapId');

    final Map<String, FetchPaymentProposedFeesResponse> updatedProposedFeesMap =
        Map<String, FetchPaymentProposedFeesResponse>.from(state.proposedFeesMap);
    updatedProposedFeesMap.remove(swapId);

    emit(state.copyWith(proposedFeesMap: updatedProposedFeesMap));
  }

  /// Gets proposed fees for a specific swap ID
  FetchPaymentProposedFeesResponse? getProposedFeesForSwap(String swapId) {
    return state.proposedFeesMap[swapId];
  }

  /// Resets the entire state to initial
  void reset() {
    _logger.info('Resetting AmountlessBtcCubit state');
    emit(AmountlessBtcState.initial());
  }

  /// Clears only the fees-related state while keeping the address
  void clearFeesState() {
    _logger.info('Clearing fees state');
    emit(
      state.copyWith(
        paymentsWaitingFeeAcceptance: <Payment>[],
        proposedFeesMap: <String, FetchPaymentProposedFeesResponse>{},
        isLoadingPayments: false,
        isLoadingFees: false,
      ),
    );
  }
}
