import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/sdk_formatted_string_extensions.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:logging/logging.dart';

export 'refund_state.dart';

final Logger _logger = Logger('RefundCubit');

/// A class that encapsulates refund request parameters
class RefundParams {
  /// The swap address for the refund
  final String swapAddress;

  /// The destination address for the refund
  final String toAddress;

  /// Constructor for RefundParams
  const RefundParams({
    required this.swapAddress,
    required this.toAddress,
  });
}

/// Cubit that handles refund operations for failed or expired swaps.
class RefundCubit extends Cubit<RefundState> {
  StreamSubscription<PaymentEvent>? _paymentEventSubscription;

  final BreezSDKLiquid _breezSdkLiquid;

  RefundCubit(this._breezSdkLiquid) : super(RefundState.initial()) {
    _initializeRefundCubit();
  }

  /// Initializes the cubit by waiting for initial SDK info and then
  /// fetching the current list of refundables.
  Future<void> _initializeRefundCubit() async {
    _logger.info('Initializing Refund Cubit');
    try {
      await _breezSdkLiquid.getInfoResponseStream.first;
      // Fire-and-forget the list refresh.
      listRefundables();
      _listenRefundEvents();
    } catch (e) {
      _logger.severe('Failed to initialize Refund Cubit', e);
      emit(state.copyWith(error: ExceptionHandler.extractMessage(e, getSystemAppLocalizations())));
    }
  }

  /// Retrieves refundables from the SDK and emits the updated state.
  Future<void> listRefundables() async {
    try {
      _logger.info('Refreshing refundables');
      final List<RefundableSwap> refundables = await _breezSdkLiquid.instance!.listRefundables();
      _logger.info(
        'Fetched ${refundables.length} refundables: '
        '${refundables.map((RefundableSwap r) => r.toFormattedString()).toList()}',
      );
      emit(state.copyWith(refundables: refundables, error: ''));
    } catch (e) {
      _logger.severe('Failed to list refundables', e);
      // In case of error, set refundables to empty list rather than leaving it unchanged
      emit(
        state.copyWith(
          refundables: <RefundableSwap>[],
          error: ExceptionHandler.extractMessage(e, getSystemAppLocalizations()),
        ),
      );
    }
  }

  /// Subscribes to payment events and refreshes refundables when a refund-
  /// related event is detected.
  void _listenRefundEvents() {
    _logger.info('Listening to refund-related events');
    _paymentEventSubscription = _breezSdkLiquid.paymentEventStream.listen(
      _handlePaymentEvent,
      onError: (Object e) => _logger.severe('Error in payment event stream', e),
    );
  }

  /// Handles incoming payment events and refreshes refundables when needed
  ///
  /// [paymentEvent] The payment event to handle
  void _handlePaymentEvent(PaymentEvent paymentEvent) {
    _logger.info('Received payment event: ${paymentEvent.toFormattedString()}');
    if (paymentEvent.sdkEvent.isRefundRelated(hasRefundables: state.hasRefundables)) {
      _logger.info('Refund-related event detected. Refreshing refundables.');
      listRefundables();
    }
  }

  @override
  Future<void> close() {
    _paymentEventSubscription?.cancel();
    return super.close();
  }

  /// Fetches the recommended fees from the SDK.
  Future<RecommendedFees> _fetchRecommendedFees() async {
    try {
      _logger.info('Fetching recommended fees');
      final RecommendedFees fees = await _breezSdkLiquid.instance!.recommendedFees();
      _logger.info('Fetched recommended fees: ${fees.toFormattedString()}');
      return fees;
    } catch (e) {
      _logger.severe('Failed to fetch recommended fees', e);
      rethrow;
    }
  }

  /// Fetches refund fee options for a given [params].
  ///
  /// Returns a list of [RefundFeeOption] representing different fee rates.
  Future<List<RefundFeeOption>> fetchRefundFeeOptions({
    required RefundParams params,
  }) async {
    try {
      _logger.info(
        'Fetching refund fee options for swapAddress: ${params.swapAddress}, '
        'toAddress: ${params.toAddress}',
      );

      final RecommendedFees recommendedFees = await _fetchRecommendedFees();
      final List<RefundFeeOption> feeOptions = await _constructFeeOptionList(
        params: params,
        recommendedFees: recommendedFees,
      );

      _logger.info('Constructed fee options: $feeOptions');
      return feeOptions;
    } catch (e) {
      _logger.severe('Failed to fetch refund fee options', e);
      emit(state.copyWith(error: ExceptionHandler.extractMessage(e, getSystemAppLocalizations())));
      rethrow;
    }
  }

  /// Constructs a list of refund fee options using [recommendedFees].
  ///
  /// Each option corresponds to a different processing speed.
  Future<List<RefundFeeOption>> _constructFeeOptionList({
    required RefundParams params,
    required RecommendedFees recommendedFees,
  }) async {
    _logger.info('Constructing refund fee options for swapAddress: ${params.swapAddress}');

    // Map each processing speed to its corresponding fee.
    final Map<ProcessingSpeed, BigInt> processingSpeedToFeeMap = <ProcessingSpeed, BigInt>{
      ProcessingSpeed.values[0]: recommendedFees.hourFee,
      ProcessingSpeed.values[1]: recommendedFees.halfHourFee,
      ProcessingSpeed.values[2]: recommendedFees.fastestFee,
    };

    try {
      final List<Future<RefundFeeOption>> feeOptionFutures = processingSpeedToFeeMap.entries
          .map(
            (MapEntry<ProcessingSpeed, BigInt> entry) => _createRefundFeeOption(
              processingSpeed: entry.key,
              feeRate: entry.value,
              params: params,
            ),
          )
          .toList();

      final List<RefundFeeOption> feeOptions = await Future.wait(feeOptionFutures);
      _logger.info('Successfully constructed refund fee options: $feeOptions');
      return feeOptions;
    } catch (e) {
      _logger.severe('Failed to construct refund fee options', e);
      rethrow;
    }
  }

  /// Creates a single refund fee option for the given [processingSpeed] and [feeRate].
  ///
  /// [processingSpeed] The processing speed for this fee option
  /// [feeRate] The fee rate in sat/vbyte
  /// [params] The refund parameters
  Future<RefundFeeOption> _createRefundFeeOption({
    required ProcessingSpeed processingSpeed,
    required BigInt feeRate,
    required RefundParams params,
  }) async {
    try {
      _logger.info('Creating refund fee option for processingSpeed: $processingSpeed, feeRate: $feeRate');
      final PrepareRefundRequest request = PrepareRefundRequest(
        swapAddress: params.swapAddress,
        feeRateSatPerVbyte: feeRate.toInt(),
        refundAddress: params.toAddress,
      );

      final PrepareRefundResponse response = await prepareRefund(request);

      _logger.info('Created refund fee option for $processingSpeed with fee ${response.txFeeSat} sat');
      return RefundFeeOption(
        processingSpeed: processingSpeed,
        feeRateSatPerVbyte: feeRate,
        prepareRefundResponse: response,
      );
    } catch (e) {
      _logger.severe('Error creating refund fee option for processingSpeed: $processingSpeed', e);
      rethrow;
    }
  }

  /// Prepares a refund transaction using the provided [req].
  ///
  /// Returns a [PrepareRefundResponse] on success.
  Future<PrepareRefundResponse> prepareRefund(PrepareRefundRequest req) async {
    try {
      _logger.info(
        'Preparing refund for swap ${req.swapAddress} to ${req.refundAddress} '
        'with fee ${req.feeRateSatPerVbyte} sat/vbyte',
      );

      final PrepareRefundResponse response = await _breezSdkLiquid.instance!.prepareRefund(req: req);
      _logger.info('Prepared refund response: ${response.toFormattedString()}');
      return response;
    } catch (e) {
      _logger.severe('Failed to prepare refund', e);
      rethrow;
    }
  }

  /// Broadcasts a refund transaction for a failed or expired swap.
  ///
  /// Emits the transaction ID upon success and returns the [RefundResponse].
  Future<RefundResponse> refund({required RefundRequest req}) async {
    try {
      _logger.info('Processing refund for ${req.toFormattedString()}');
      final RefundResponse refundResponse = await _breezSdkLiquid.instance!.refund(req: req);

      _logger.info('Refund succeeded. txId: ${refundResponse.refundTxId}');
      emit(state.copyWith(refundTxId: refundResponse.refundTxId, error: ''));
      return refundResponse;
    } catch (e) {
      _logger.severe('Failed to refund', e);
      emit(state.copyWith(error: ExceptionHandler.extractMessage(e, getSystemAppLocalizations())));
      rethrow;
    } finally {
      _logger.info('Refund process completed, refreshing refundables list.');
      await listRefundables();
    }
  }

  /// Enables rebroadcasting of refunds by updating the state.
  ///
  /// This sets `rebroadcastEnabled` to `true`, allowing the UI to trigger
  /// a refund rebroadcast if needed.
  void enableRebroadcast() {
    emit(state.copyWith(rebroadcastEnabled: true));
  }
}
