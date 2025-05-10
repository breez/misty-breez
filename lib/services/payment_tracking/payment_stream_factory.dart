import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/services/services.dart';

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
      filter: (PaymentData payment) =>
          payment.paymentType == PaymentType.receive &&
          payment.status == PaymentState.pending &&
          payment.details is PaymentDetails_Bitcoin,
      paymentTypeName: 'Bitcoin',
    );

    _lnAddressPaymentStream = _createFilteredPaymentStream(
      filter: (PaymentData payment) =>
          payment.paymentType == PaymentType.receive &&
          payment.status == PaymentState.pending &&
          payment.details is! PaymentDetails_Bitcoin,
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
    final Stream<dynamic> stream = _resolveStream(config);

    // If there is no delay, return subscription immediately
    if (config.trackingDelay == Duration.zero) {
      return _createStreamSubscription(stream, config.onPaymentComplete);
    } else {
      // Wait for the delay duration before subscribing
      await Future<void>.delayed(config.trackingDelay);
      return _createStreamSubscription(stream, config.onPaymentComplete);
    }
  }

  /// Resolves the appropriate stream for the given config.
  Stream<dynamic> _resolveStream(PaymentTrackingConfig config) {
    if (isOutgoingPayment(config.paymentType)) {
      return _createPaymentEventStream(config.destination!, config.paymentType);
    }

    switch (config.trackingType) {
      case PaymentTrackingType.lightningAddress:
        return _lnAddressPaymentStream;
      case PaymentTrackingType.bitcoinTransaction:
        return _btcPaymentStream;
      case PaymentTrackingType.lightningInvoice:
        return _createPaymentEventStream(config.destination!, config.paymentType);
      case PaymentTrackingType.none:
        throw 'Invalid tracking type';
    }
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

  /// Creates a filtered stream of payments based on custom filter
  Stream<PaymentData> _createFilteredPaymentStream({
    required bool Function(PaymentData) filter,
    required String paymentTypeName,
  }) {
    final StreamController<PaymentData> controller = StreamController<PaymentData>.broadcast();
    _paymentsCubit.stream
        .skip(1) // Skip initial state
        .distinct(_isDistinctPayment)
        .map((PaymentsState state) => state.payments.isNotEmpty ? state.payments.first : null)
        .where((PaymentData? payment) => payment != null && filter(payment))
        .cast<PaymentData>()
        .listen(
      (PaymentData payment) {
        _logger.info('$paymentTypeName Payment Received! Id: ${payment.id}');
        controller.add(payment);
      },
      onError: controller.addError,
      onDone: controller.close,
    );
    return controller.stream;
  }

  bool _isDistinctPayment(PaymentsState a, PaymentsState b) {
    if (a.payments.isEmpty || b.payments.isEmpty) {
      return true;
    }
    return a.payments.first.id == b.payments.first.id;
  }

  void dispose() {
    _delayedTrackingTimer?.cancel();
    _delayedTrackingTimer = null;
  }
}
