import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/receive_payment/widgets/destination_widget/destination_header.dart';
import 'package:l_breez/routes/receive_payment/widgets/destination_widget/destination_qr_widget.dart';
import 'package:l_breez/routes/receive_payment/widgets/successful_payment/successful_payment.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/flushbar.dart';
import 'package:logging/logging.dart';

final _log = Logger("DestinationWidget");

class DestinationWidget extends StatefulWidget {
  final AsyncSnapshot<ReceivePaymentResponse>? snapshot;
  final String? destination;
  final String? title;
  final void Function()? onLongPress;
  final Widget? infoWidget;
  final bool isLnAddress;

  const DestinationWidget({
    super.key,
    this.snapshot,
    this.destination,
    this.title,
    this.onLongPress,
    this.infoWidget,
    this.isLnAddress = false,
  });

  @override
  State<DestinationWidget> createState() => _DestinationWidgetState();
}

class _DestinationWidgetState extends State<DestinationWidget> {
  StreamSubscription<PaymentData?>? _receivedPaymentSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.isLnAddress) _trackNewPayments();
  }

  @override
  void didUpdateWidget(covariant DestinationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // For receive payment pages other than LN Address, user input is required before creating an invoice.
    // Therefore, they rely on `didUpdateWidget` instead of `initState` to capture updates after
    // initial widget setup.
    if (!widget.isLnAddress) {
      _trackPaymentEvents(getUpdatedDestination(oldWidget));
    }
  }

  String? getUpdatedDestination(DestinationWidget oldWidget) {
    final hasUpdatedDestination = widget.destination != oldWidget.destination;
    if (widget.destination != null && hasUpdatedDestination) {
      return widget.destination!;
    }

    final newSnapshotDestination = widget.snapshot?.data?.destination;
    final oldSnapshotDestination = oldWidget.snapshot?.data?.destination;
    if (newSnapshotDestination != null && newSnapshotDestination != oldSnapshotDestination) {
      return newSnapshotDestination;
    }

    return null;
  }

  @override
  void dispose() {
    _receivedPaymentSubscription?.cancel();
    super.dispose();
  }

  void _trackNewPayments() {
    _log.info("Tracking new payments.");
    final paymentsCubit = context.read<PaymentsCubit>();
    _receivedPaymentSubscription?.cancel();
    _receivedPaymentSubscription = paymentsCubit.stream
        .skip(1) // Skips the initial state
        .distinct((previous, next) => previous.payments.first.id == next.payments.first.id)
        .map((paymentState) => paymentState.payments.isNotEmpty ? paymentState.payments.first : null)
        .where(
          (payment) =>
              payment != null &&
              payment.paymentType == PaymentType.receive &&
              payment.status == PaymentState.pending,
        )
        .listen(
      (payment) {
        // Null cases are filtered out on where clause
        final newPayment = payment!;
        _log.info(
          "Payment Received! Id: ${newPayment.id} Destination: ${newPayment.destination}, Status: ${newPayment.status}",
        );
        _onPaymentFinished(true);
      },
      onError: (e) => _onTrackPaymentError(e),
    );
  }

  void _trackPaymentEvents(String? destination) {
    final inputCubit = context.read<InputCubit>();
    inputCubit
        .trackPaymentEvents(destination)
        .then((_) => _onPaymentFinished(true))
        .catchError((e) => _onTrackPaymentError(e));
  }

  void _onTrackPaymentError(dynamic e) {
    _log.warning("Failed to track payment", e);
    if (mounted) {
      showFlushbar(context, message: extractExceptionMessage(e, context.texts()));
    }
    _onPaymentFinished(false);
  }

  void _onPaymentFinished(bool isSuccess) {
    if (!mounted) return;
    if (isSuccess) {
      final navigator = Navigator.of(context);
      // Only pop if the destination is not an LN Address,
      // as there's no way to 1:1 match payments on the LN Address page.
      if (!widget.isLnAddress) navigator.pop();
      navigator.push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => const SuccessfulPaymentRoute(particlesEnabled: false),
        ),
      );
    } else {
      if (!widget.isLnAddress) {
        showFlushbar(context, title: "", message: "Payment failed.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: DestinationHeader(
            snapshot: widget.snapshot,
            destination: widget.destination,
            paymentMethod: widget.title,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: DestinationQRWidget(
            snapshot: widget.snapshot,
            destination: widget.destination,
            onLongPress: widget.onLongPress,
            infoWidget: widget.infoWidget,
          ),
        ),
      ],
    );
  }
}
