import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';

export 'widgets/widgets.dart';

final Logger _logger = Logger('DestinationWidget');

// Delay to allow user interaction before showing "Payment Received!" sheet.
const Duration lnAddressTrackingDelay = Duration(milliseconds: 1600);

class DestinationWidget extends StatefulWidget {
  final AsyncSnapshot<ReceivePaymentResponse>? snapshot;
  final String? destination;
  final String? lnAddress;
  final String? paymentLabel;
  final void Function()? onLongPress;
  final Widget? infoWidget;
  final bool isBitcoinPayment;

  const DestinationWidget({
    super.key,
    this.snapshot,
    this.destination,
    this.lnAddress,
    this.paymentLabel,
    this.onLongPress,
    this.infoWidget,
    this.isBitcoinPayment = false,
  });

  @override
  State<DestinationWidget> createState() => _DestinationWidgetState();
}

class _DestinationWidgetState extends State<DestinationWidget> {
  StreamSubscription<Payment>? _trackPaymentEventsSubscription;

  Future<void> _trackPaymentEvents({String? expectedDestination}) async {
    final PaymentsCubit paymentsCubit = context.read<PaymentsCubit>();
    _trackPaymentEventsSubscription?.cancel();

    final bool Function(Payment)? paymentFilter = await _buildPaymentFilter(expectedDestination);
    if (paymentFilter == null) {
      _logger.warning('Skipping tracking payment events.');
      return;
    }

    _trackPaymentEventsSubscription = paymentsCubit.trackPaymentEvents(
      paymentFilter: paymentFilter,
      onData: _onTrackPaymentSucceed,
      onError: _onTrackPaymentError,
    );
  }

  Future<bool Function(Payment)?> _buildPaymentFilter(String? expectedDestination) async {
    if (widget.lnAddress != null) {
      await Future<void>.delayed(lnAddressTrackingDelay);
      _logger.info('Tracking incoming payments to Lightning Address.');
      return (Payment p) =>
          p.paymentType == PaymentType.receive &&
          p.details is PaymentDetails_Lightning &&
          (p.status == PaymentState.pending || p.status == PaymentState.complete);
    }

    if (expectedDestination != null) {
      _logger.info('Tracking incoming payments to destination: $expectedDestination');
      // TODO(erdemyerebasmaz): Cleanup isBitcoinPayment workaround once SDK includes destination or swap ID on resulting payment.
      // Depends on: https://github.com/breez/breez-sdk-liquid/issues/913
      // Treat any incoming BTC payment as valid until we can match it via destination (BIP21 URI) or swap ID.
      return (Payment p) =>
          (widget.isBitcoinPayment
              ? p.details is PaymentDetails_Bitcoin
              : p.destination == expectedDestination) &&
          (p.status == PaymentState.pending || p.status == PaymentState.complete);
    }

    _logger.warning('Missing destination or LN Address.');
    return null;
  }

  void _onTrackPaymentSucceed(Payment p) {
    _logger.info(
      'Incoming payment detected!'
      '${p.destination?.isNotEmpty == true ? ' Destination: ${p.destination}' : ''}',
    );
    _onPaymentFinished(true);
  }

  void _onTrackPaymentError(Object e) {
    _logger.warning('Failed to track incoming payments.', e);
    if (mounted) {
      showFlushbar(context, message: ExceptionHandler.extractMessage(e, context.texts()));
    }
    _onPaymentFinished(false);
  }

  @override
  void initState() {
    super.initState();
    _trackPaymentEvents(expectedDestination: widget.destination);
  }

  @override
  void dispose() {
    _cancelTrackingPaymentEvents();
    super.dispose();
  }

  void _cancelTrackingPaymentEvents() {
    if (_trackPaymentEventsSubscription != null) {
      _trackPaymentEventsSubscription?.cancel();
      _logger.info('Cancelled tracking payment events for ${widget.paymentLabel}.');
    }
  }

  void _onPaymentFinished(bool isSuccess) {
    if (!mounted) {
      return;
    }
    _cancelTrackingPaymentEvents();
    if (isSuccess) {
      showPaymentReceivedSheet(context);
    } else {
      showFlushbar(context, title: '', message: 'Payment failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: DestinationQRWidget(
            snapshot: widget.snapshot,
            destination: widget.destination,
            lnAddress: widget.lnAddress,
            paymentLabel: widget.paymentLabel,
            onLongPress: widget.onLongPress,
            infoWidget: widget.infoWidget,
          ),
        ),
      ],
    );
  }
}
