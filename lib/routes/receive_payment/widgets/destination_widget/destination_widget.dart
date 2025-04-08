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
  StreamSubscription<PaymentData?>? _receivedPaymentSubscription;
  StreamSubscription<void>? _trackPaymentEventsSubscription;
  Timer? _delayedTrackingTimer;

  @override
  void initState() {
    super.initState();
    if (widget.lnAddress != null && widget.lnAddress!.isNotEmpty) {
      // Ignore new payments for a duration upon generating LN Address.
      // This delay is added to avoid popping the page before user gets the chance to copy,
      // share or get their LN address scanned.
      _delayedTrackingTimer = Timer(
        const Duration(milliseconds: 1600),
        () {
          if (mounted) {
            _trackNewPayments();
          }
        },
      );
    }
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

        _trackPaymentEvents(updatedDestination);
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
    _receivedPaymentSubscription?.cancel();
    _trackPaymentEventsSubscription?.cancel();
    _delayedTrackingTimer?.cancel();
    super.dispose();
  }

  void _trackNewPayments() {
    _logger.info('Tracking new payments.');
    final PaymentsCubit paymentsCubit = context.read<PaymentsCubit>();
    _receivedPaymentSubscription?.cancel();
    _receivedPaymentSubscription = paymentsCubit.stream
        .skip(1) // Skips the initial state
        .distinct(
          (PaymentsState previous, PaymentsState next) =>
              previous.payments.first.id == next.payments.first.id,
        )
        .map(
          (PaymentsState paymentState) =>
              paymentState.payments.isNotEmpty ? paymentState.payments.first : null,
        )
        .where(
          (PaymentData? payment) =>
              payment != null &&
              payment.paymentType == PaymentType.receive &&
              payment.status == PaymentState.pending,
        )
        .listen(
      (PaymentData? payment) {
        // Null cases are filtered out on where clause
        final PaymentData newPayment = payment!;
        _logger.info(
          'Payment Received! Id: ${newPayment.id} Destination: ${newPayment.destination}, Status: ${newPayment.status}',
        );
        _onPaymentFinished(true);
      },
      onError: (Object e) => _onTrackPaymentError(e),
    );
  }

  void _trackPaymentEvents(String? destination) {
    final InputCubit inputCubit = context.read<InputCubit>();
    _trackPaymentEventsSubscription = inputCubit
        .trackPaymentEvents(
          destination,
          paymentType: PaymentType.receive,
        )
        .asStream()
        .listen(
          (_) => _onPaymentFinished(true),
          onError: (Object e) => _onTrackPaymentError(e),
        );
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
