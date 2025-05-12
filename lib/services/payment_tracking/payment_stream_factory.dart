import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/services/services.dart';
import 'package:rxdart/rxdart.dart';

final Logger _logger = Logger('PaymentStreamFactory');

/// Factory for creating payment-related streams
class PaymentStreamFactory {
  final BreezSDKLiquid _breezSdkLiquid;
  final PaymentsCubit _paymentsCubit;

  // Cached broadcast streams for reuse
  late final Stream<PaymentData> _btcPaymentStream;
  late final Stream<PaymentData> _lnAddressPaymentStream;

  PaymentStreamFactory(this._breezSdkLiquid, this._paymentsCubit) {
    // Initialize cached streams
    _btcPaymentStream = _createFilteredPaymentStream(
      filter: PaymentDataFilters.isPendingIncomingBtcPayment,
      paymentTypeName: 'Bitcoin',
    );

    _lnAddressPaymentStream = _createFilteredPaymentStream(
      filter: PaymentDataFilters.isPendingIncomingLnPayment,
      paymentTypeName: 'Lightning Address',
    );
  }

  /// Public access to payment streams
  Stream<PaymentData> get btcPaymentStream => _btcPaymentStream;
  Stream<PaymentData> get lnAddressPaymentStream => _lnAddressPaymentStream;

  Timer? _delayedTrackingTimer;

  /// Subscribes to the stream based on provided config
  Future<StreamSubscription<dynamic>> subscribeToStream(
    PaymentTrackingConfig config,
  ) async {
    if (config is ReceivePaymentTrackingConfig && config.trackingDelay != Duration.zero) {
      await Future<void>.delayed(config.trackingDelay);
    }
    final Stream<dynamic> stream = _resolveStream(config);
    return _createStreamSubscription(stream, config.onPaymentComplete);
  }

  /// Resolves the appropriate stream for the given config.
  Stream<dynamic> _resolveStream(PaymentTrackingConfig config) {
    return switch (config) {
      SendPaymentTrackingConfig() => _createPaymentEventStream(config.destination, config.paymentType),
      ReceivePaymentTrackingConfig() => switch (config.trackingType) {
          PaymentTrackingType.lightningAddress => _lnAddressPaymentStream,
          PaymentTrackingType.bitcoinTransaction => _btcPaymentStream,
          PaymentTrackingType.lightningInvoice =>
            _createPaymentEventStream(config.destination!, config.paymentType),
          // This can't be reached as ReceivePaymentTrackingConfig is pre-validated.
          _ => throw ArgumentError('Invalid tracking type: ${config.trackingType}')
        },
      _ => throw ArgumentError('Unknown config type: ${config.runtimeType}')
    };
  }

  /// Creates a subscription with standardized error handling
  StreamSubscription<T> _createStreamSubscription<T>(
    Stream<T> stream,
    PaymentCompleteCallback onComplete,
  ) {
    return stream.listen(
      (_) => onComplete(true),
      onError: (Object error) {
        _logger.warning('Payment tracking error', error);
        onComplete(false);
      },
    );
  }

  /// Creates a filtered payment event stream for a specific destination
  Stream<PaymentEvent> _createPaymentEventStream(
    String destination,
    PaymentType paymentType,
  ) {
    return _breezSdkLiquid.paymentEventStream.where(
      (PaymentEvent event) => PaymentMatchers.isPaymentForDestination(
        event.payment,
        destination,
        paymentType,
      ),
    );
  }

  /// Creates a filtered stream of payments based on provided filter
  Stream<PaymentData> _createFilteredPaymentStream({
    required bool Function(PaymentData) filter,
    required String paymentTypeName,
  }) {
    return _paymentsCubit.stream
        .skip(1) // Skip initial state
        .distinct(_isDistinctPayment)
        .switchMap(_filterPayment(filter, paymentTypeName));
  }

  /// Considers payments distinct if either list is empty or IDs differ
  bool _isDistinctPayment(PaymentsState a, PaymentsState b) {
    if (a.payments.isEmpty || b.payments.isEmpty) {
      return true;
    }
    return a.payments.first.id == b.payments.first.id;
  }

  /// Extracts payments that match the filter criteria and emits them as a stream
  Stream<PaymentData> Function(PaymentsState) _filterPayment(
    bool Function(PaymentData) filter,
    String paymentTypeName,
  ) {
    return (PaymentsState state) {
      try {
        // Find first payment matching the filter
        final PaymentData payment = state.payments.firstWhere(filter);
        _logger.info('$paymentTypeName Payment Received! Id: ${payment.id}');
        return Stream<PaymentData>.value(payment);
      } catch (e) {
        // Note: Returning empty stream effectively filters out this payment from the result.
        // This is how switchMap filtering works, empty streams are flattened away.
        return const Stream<PaymentData>.empty();
      }
    };
  }

  void dispose() {
    _delayedTrackingTimer?.cancel();
    _delayedTrackingTimer = null;
  }
}
