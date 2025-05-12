import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/services/services.dart';

final Logger _logger = Logger('PaymentStreamFactory');

/// Factory for creating payment-related streams
class PaymentStreamFactory {
  final BreezSDKLiquid _breezSdkLiquid;

  PaymentStreamFactory(this._breezSdkLiquid);

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
    return _breezSdkLiquid.paymentEventStream.where(
      (PaymentEvent event) => event.payment.matches(config),
    );
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

  void dispose() {
    _delayedTrackingTimer?.cancel();
    _delayedTrackingTimer = null;
  }
}
