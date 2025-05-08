import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/services/services.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:provider/provider.dart';

export 'widgets/widgets.dart';

class DestinationWidget extends StatefulWidget {
  final PaymentMethod paymentMethod;
  final AsyncSnapshot<ReceivePaymentResponse>? snapshot;
  final String? destination;
  final String? lnAddress;
  final void Function()? onLongPress;
  final Widget? infoWidget;

  const DestinationWidget({
    required this.paymentMethod,
    this.snapshot,
    this.destination,
    this.lnAddress,
    this.onLongPress,
    this.infoWidget,
    super.key,
  });

  @override
  State<DestinationWidget> createState() => _DestinationWidgetState();
}

class _DestinationWidgetState extends State<DestinationWidget> {
  late final PaymentTrackingService paymentTrackingService;

  @override
  void initState() {
    super.initState();
    paymentTrackingService = Provider.of<PaymentTrackingService>(context, listen: false);
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

  bool _hasUpdatedDestination(DestinationWidget oldWidget) {
    final bool hasUpdatedDestination = widget.destination != oldWidget.destination;

    final String? newSnapshotDestination = widget.snapshot?.data?.destination;
    final String? oldSnapshotDestination = oldWidget.snapshot?.data?.destination;
    final bool hasUpdatedSnapshotDestination =
        newSnapshotDestination != null && newSnapshotDestination != oldSnapshotDestination;
    return hasUpdatedDestination || hasUpdatedSnapshotDestination;
  }

  @override
  void dispose() {
    paymentTrackingService.stopTracking();
    super.dispose();
  }

  void _setupPaymentTracking() {
    paymentTrackingService.startTracking(
      trackingType: widget.paymentMethod.trackingType,
      destination: widget.destination ?? widget.snapshot?.data?.destination,
      lnAddress: widget.lnAddress,
      onPaymentReceived: _onPaymentFinished,
    );
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
            paymentMethod: widget.paymentMethod.getLocalizedName(context),
            onLongPress: widget.onLongPress,
            infoWidget: widget.infoWidget,
          ),
        ),
      ],
    );
  }
}
