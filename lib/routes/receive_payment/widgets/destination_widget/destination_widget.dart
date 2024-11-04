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
  StreamSubscription<PaymentsState>? _paymentStateSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.isLnAddress) _trackNewPayments();
  }

  @override
  void didUpdateWidget(covariant DestinationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// Receive pages other than LN Address wait for user input for invoice to be created, hence they rely on didUpdateWidget and not initState
    if (!widget.isLnAddress) {
      final hasUpdatedDestination = widget.destination != oldWidget.destination;
      if (hasUpdatedDestination || _hasNewDestination(widget.snapshot, oldWidget.snapshot)) {
        _trackPaymentEvents(widget.destination ?? widget.snapshot?.data?.destination);
      }
    }
  }

  @override
  void dispose() {
    _paymentStateSubscription?.cancel();
    super.dispose();
  }

  void _trackNewPayments() {
    final paymentsCubit = context.read<PaymentsCubit>();
    _paymentStateSubscription?.cancel();
    _paymentStateSubscription = paymentsCubit.stream
        .distinct((previous, next) => previous.payments.first == next.payments.first)
        .listen((paymentState) => handleNewPayment(paymentState), onError: (e) => _onTrackPaymentError(e));
  }

  void handleNewPayment(PaymentsState paymentState) {
    final latestPayment = paymentState.payments.first;
    final isPendingOrComplete =
        (latestPayment.status == PaymentState.pending || latestPayment.status == PaymentState.complete);
    final isPaymentReceived = latestPayment.paymentType == PaymentType.receive && isPendingOrComplete;

    if (isPaymentReceived) {
      _log.info(
          "Payment Received! Destination: ${latestPayment.destination}, Status: ${latestPayment.status}");
    }
    _onPaymentFinished(isPaymentReceived);
  }

  bool _hasNewDestination(
    AsyncSnapshot<ReceivePaymentResponse>? newSnapshot,
    AsyncSnapshot<ReceivePaymentResponse>? oldSnapshot,
  ) {
    return newSnapshot?.hasData == true &&
        oldSnapshot?.hasData == true &&
        newSnapshot!.data!.destination != oldSnapshot!.data!.destination;
  }

  void _trackPaymentEvents(String? destination) {
    final inputCubit = context.read<InputCubit>();
    inputCubit
        .trackPayment(destination)
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
    Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (isSuccess) {
        final navigator = Navigator.of(context);
        if (!widget.isLnAddress) {
          navigator.pop(); // Only pop if destination is not an LN Address
        }
        // Show successful payment route
        navigator.push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => const SuccessfulPaymentRoute(),
          ),
        );
      } else {
        if (widget.isLnAddress) {
          _paymentStateSubscription?.cancel();
        } else {
          showFlushbar(context, title: "", message: "Payment failed.");
        }
      }
    });
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
