import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:provider/provider.dart';

export 'widgets/widgets.dart';

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
    this.snapshot,
    this.destination,
    this.lnAddress,
    this.paymentMethod,
    this.onLongPress,
    this.infoWidget,
    super.key,
  });

  @override
  State<DestinationWidget> createState() => _DestinationWidgetState();
}

class _DestinationWidgetState extends State<DestinationWidget> {
  StreamSubscription<Payment>? _paymentSubscription;

  @override
  void initState() {
    super.initState();
    _setupPaymentTracking();
  }

  @override
  void didUpdateWidget(covariant DestinationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // For receive payment pages other than LN Address, user input is required before creating an invoice.
    // Therefore, they rely on `didUpdateWidget` instead of `initState` to capture updates after
    // initial widget setup.
    if (!(widget.lnAddress != null && widget.lnAddress!.isNotEmpty)) {
      if (_hasUpdatedDestination(oldWidget)) {
        _setupPaymentTracking();
      }
    }
  }

  @override
  void dispose() {
    _paymentSubscription?.cancel();
    super.dispose();
  }

  bool _hasUpdatedDestination(DestinationWidget oldWidget) {
    final bool hasUpdatedDestination = widget.destination != oldWidget.destination;

    final String? newSnapshotDestination = widget.snapshot?.data?.destination;
    final String? oldSnapshotDestination = oldWidget.snapshot?.data?.destination;
    final bool hasUpdatedSnapshotDestination =
        newSnapshotDestination != null && newSnapshotDestination != oldSnapshotDestination;
    return hasUpdatedDestination || hasUpdatedSnapshotDestination;
  }

  void _setupPaymentTracking() async {
    final PaymentsCubit paymentsCubit = context.read<PaymentsCubit>();
    final String? destination = widget.destination ?? widget.snapshot?.data?.destination;

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

    _paymentSubscription?.cancel();
    _paymentSubscription = paymentsCubit.trackPayment(
      predicate: predicate,
      onPaymentComplete: _onPaymentComplete,
    );
  }

  void _onPaymentComplete(bool isSuccess) {
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
