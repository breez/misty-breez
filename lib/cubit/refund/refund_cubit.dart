import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/sdk_formatted_string_extensions.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:logging/logging.dart';

export 'refund_state.dart';

final Logger _logger = Logger('RefundCubit');

/// Cubit that handles refund operations.
class RefundCubit extends Cubit<RefundState> {
  StreamSubscription<PaymentEvent>? _paymentEventSubscription;

  final BreezSDKLiquid _breezSdkLiquid;

  RefundCubit(this._breezSdkLiquid) : super(RefundState.initial()) {
    _initializeRefundCubit();
    _listenRefundEvents();
  }

  /// Initializes the cubit by waiting for initial SDK info and then
  /// fetching the current list of refundables.
  Future<void> _initializeRefundCubit() async {
    _logger.info('Initializing Refund Cubit');
    try {
      await _breezSdkLiquid.getInfoResponseStream.first;
      // Fire-and-forget the list refresh.
      listRefundables();
    } catch (e) {
      _logger.severe('Failed to initialize Refund Cubit', e);
    }
  }

  /// Retrieves refundables from the SDK and emits the updated state.
  Future<void> listRefundables() async {
    try {
      _logger.info('Refreshing refundables');
      final List<RefundableSwap> refundables = await _breezSdkLiquid.instance!.listRefundables();
      _logger.info(
        'Fetched refundables: ${refundables.map((RefundableSwap r) => r.toFormattedString()).toList()}',
      );
      emit(state.copyWith(refundables: refundables));
    } catch (e) {
      _logger.severe('Failed to list refundables', e);
      emit(state.copyWith());
    }
  }

  /// Subscribes to payment events and refreshes refundables when a refund-
  /// related event is detected.
  void _listenRefundEvents() {
    _logger.info('Listening to refund-related events');
    _paymentEventSubscription = _breezSdkLiquid.paymentEventStream.listen(
      (PaymentEvent paymentEvent) {
        _logger.info('Received payment event: ${paymentEvent.toFormattedString()}');
        if (paymentEvent.sdkEvent.isRefundRelated(hasRefundables: state.hasRefundables)) {
          _logger.info('Refund-related event detected. Refreshing refundables.');
          listRefundables();
        }
      },
      onError: (Object e) => _logger.severe('Error in _listenRefundEvents', e),
    );
  }

  @override
  Future<void> close() {
    _paymentEventSubscription?.cancel();
    return super.close();
  }

  /// Fetches the recommended fees from the SDK.
  Future<RecommendedFees> _recommendedFees() async {
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

  /// Fetches refund fee options for a given [swapAddress] and [toAddress].
  ///
  /// Returns a list of [RefundFeeOption] representing different fee rates.
  Future<List<RefundFeeOption>> fetchRefundFeeOptions({
    required String toAddress,
    required String swapAddress,
  }) async {
    try {
      _logger.info('Fetching refund fee options for swapAddress: $swapAddress, toAddress: $toAddress');
      final RecommendedFees recommendedFees = await _recommendedFees();
      final List<RefundFeeOption> feeOptions = await _constructFeeOptionList(
        toAddress: toAddress,
        swapAddress: swapAddress,
        recommendedFees: recommendedFees,
      );
      _logger.info('Constructed fee options: $feeOptions');
      return feeOptions;
    } catch (e) {
      _logger.severe('Failed to fetch refund fee options', e);
      emit(RefundState(error: extractExceptionMessage(e, getSystemAppLocalizations())));
      rethrow;
    }
  }

  /// Constructs a list of refund fee options using [recommendedFees].
  ///
  /// Each option corresponds to a different processing speed.
  Future<List<RefundFeeOption>> _constructFeeOptionList({
    required String toAddress,
    required String swapAddress,
    required RecommendedFees recommendedFees,
  }) async {
    _logger.info('Constructing refund fee options for swapAddress: $swapAddress');

    // Map each processing speed to its corresponding fee.
    final Map<ProcessingSpeed, BigInt> processingSpeedToFeeMap = <ProcessingSpeed, BigInt>{
      ProcessingSpeed.values[0]: recommendedFees.hourFee,
      ProcessingSpeed.values[1]: recommendedFees.halfHourFee,
      ProcessingSpeed.values[2]: recommendedFees.fastestFee,
    };

    try {
      final List<RefundFeeOption> feeOptions = await Future.wait(
        processingSpeedToFeeMap.entries.map(
          (MapEntry<ProcessingSpeed, BigInt> entry) => _createRefundFeeOption(
            processingSpeed: entry.key,
            feeRate: entry.value,
            swapAddress: swapAddress,
            toAddress: toAddress,
          ),
        ),
      );
      _logger.info('Successfully constructed refund fee options: $feeOptions');
      return feeOptions;
    } catch (e) {
      _logger.severe('Failed to construct refund fee options', e);
      rethrow;
    }
  }

  /// Creates a single refund fee option for the given [processingSpeed] and [feeRate].
  Future<RefundFeeOption> _createRefundFeeOption({
    required ProcessingSpeed processingSpeed,
    required BigInt feeRate,
    required String swapAddress,
    required String toAddress,
  }) async {
    try {
      _logger.info('Creating refund fee option for processingSpeed: $processingSpeed, feeRate: $feeRate');
      final PrepareRefundRequest request = PrepareRefundRequest(
        swapAddress: swapAddress,
        feeRateSatPerVbyte: feeRate.toInt(),
        refundAddress: toAddress,
      );
      final PrepareRefundResponse response = await prepareRefund(request);
      _logger.info('Successfully created refund fee option for $processingSpeed');
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
        'Preparing refund for swap ${req.swapAddress} to ${req.refundAddress} with fee ${req.feeRateSatPerVbyte}',
      );
      final PrepareRefundResponse response = await _breezSdkLiquid.instance!.prepareRefund(req: req);
      _logger.info('Prepared refund response: $response');
      return response;
    } catch (e) {
      _logger.severe('Failed to prepare refund', e);
      rethrow;
    }
  }

  /// Broadcasts a refund transaction for a failed or expired swap.
  ///
  /// Emits the transaction ID upon success.
  Future<RefundResponse> refund({required RefundRequest req}) async {
    try {
      _logger.info(
        'Refunding swap ${req.swapAddress} to ${req.refundAddress} with fee ${req.feeRateSatPerVbyte}',
      );
      final RefundResponse refundResponse = await _breezSdkLiquid.instance!.refund(req: req);
      _logger.info('Refund succeeded. txId: ${refundResponse.refundTxId}');
      emit(state.copyWith(refundTxId: refundResponse.refundTxId, error: ''));
      return refundResponse;
    } catch (e) {
      _logger.severe('Failed to refund swap', e);
      emit(state.copyWith(error: extractExceptionMessage(e, getSystemAppLocalizations())));
      rethrow;
    }
  }
}
