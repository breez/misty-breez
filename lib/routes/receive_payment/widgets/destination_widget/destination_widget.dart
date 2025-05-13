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
  final String? paymentMethod;
  final void Function()? onLongPress;
  final Widget? infoWidget;

  const DestinationWidget({
    super.key,
    this.snapshot,
    this.destination,
    this.lnAddress,
    this.paymentMethod,
    this.onLongPress,
    this.infoWidget,
  });

  @override
  State<DestinationWidget> createState() => _DestinationWidgetState();
}

class _DestinationWidgetState extends State<DestinationWidget> {
  StreamSubscription<Payment>? _trackPaymentEventsSubscription;

  void _trackPaymentEvents({String? destination}) async {
    final PaymentsCubit paymentsCubit = context.read<PaymentsCubit>();

    bool Function(Payment) predicate;
    if (widget.lnAddress != null) {
      // LN Address is a static identifier; and if made public, anyone can send payments at any time.
      // Without this delay, a new payment can interrupt the user by showing "Payment Received!" sheet
      // before they have a chance to copy/share their address.
      await Future<void>.delayed(lnAddressTrackingDelay);

      predicate = (Payment p) =>
          p.paymentType == PaymentType.receive &&
          p.details is PaymentDetails_Lightning &&
          (p.status == PaymentState.pending || p.status == PaymentState.complete);
    } else if (destination != null) {
      predicate = (Payment p) =>
          p.destination == destination &&
          (p.status == PaymentState.pending || p.status == PaymentState.complete);
    } else {
      return;
    }

    _trackPaymentEventsSubscription?.cancel();
    _trackPaymentEventsSubscription = paymentsCubit.trackPaymentEvents(
      predicate: predicate,
      onData: (Payment p) {
        _logger.info('Incoming payment detected! Destination: ${p.destination}');
        _onPaymentFinished(true);
      },
      onError: (Object e) => _onTrackPaymentError(e),
    );
  }

  @override
  void initState() {
    super.initState();
    _trackPaymentEvents();
  }

  @override
  void didUpdateWidget(covariant DestinationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // For receive payment pages other than LN Address, user input is required before creating an invoice.
    // Therefore, they rely on `didUpdateWidget` instead of `initState` to capture updates after
    // initial widget setup.
    if (!(widget.lnAddress != null && widget.lnAddress!.isNotEmpty)) {
      final String? updatedDestination = getUpdatedDestination(oldWidget);
      if (updatedDestination != null) {
        // Cancel existing tracking before starting a new one
        _trackPaymentEventsSubscription?.cancel();
        _trackPaymentEventsSubscription = null;

        _trackPaymentEvents(destination: updatedDestination);
      }
    }
  }

  String? getUpdatedDestination(DestinationWidget oldWidget) {
    final bool hasUpdatedDestination = widget.destination != oldWidget.destination;
    if (widget.destination != null && hasUpdatedDestination) {
      return widget.destination!;
    }

    final String? newSnapshotDestination = widget.snapshot?.data?.destination;
    final String? oldSnapshotDestination = oldWidget.snapshot?.data?.destination;
    if (newSnapshotDestination != null && newSnapshotDestination != oldSnapshotDestination) {
      return newSnapshotDestination;
    }

    return null;
  }

  @override
  void dispose() {
    _trackPaymentEventsSubscription?.cancel();
    super.dispose();
  }

  void _onTrackPaymentError(Object e) {
    _logger.warning('Failed to track payment', e);
    if (mounted) {
      showFlushbar(context, message: ExceptionHandler.extractMessage(e, context.texts()));
    }
    _onPaymentFinished(false);
  }

  void _onPaymentFinished(bool isSuccess) {
    if (!mounted) {
      return;
    }
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
            paymentMethod: widget.paymentMethod,
            onLongPress: widget.onLongPress,
            infoWidget: widget.infoWidget,
          ),
        ),
      ],
    );
  }
}
