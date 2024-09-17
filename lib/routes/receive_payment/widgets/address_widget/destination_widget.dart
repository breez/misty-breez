import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/receive_payment/lightning/widgets/widgets.dart';
import 'package:l_breez/routes/receive_payment/widgets/address_widget/destination_header.dart';
import 'package:l_breez/routes/receive_payment/widgets/address_widget/destination_qr_widget.dart';
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

  const DestinationWidget({
    super.key,
    this.snapshot,
    this.destination,
    this.title,
    this.onLongPress,
    this.infoWidget,
  });

  @override
  State<DestinationWidget> createState() => _DestinationWidgetState();
}

class _DestinationWidgetState extends State<DestinationWidget> {
  @override
  void didUpdateWidget(covariant DestinationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    String? destination = _getDestination(oldWidget);
    _trackPayment(destination);
  }

  String? _getDestination(DestinationWidget oldWidget) {
    String? destination;
    if (widget.destination != null) {
      if (widget.destination != oldWidget.destination) {
        destination = widget.destination!;
      }
    } else if ((widget.snapshot != null && widget.snapshot!.hasData) &&
        (oldWidget.snapshot != null && oldWidget.snapshot!.hasData)) {
      if (widget.snapshot!.data!.destination != oldWidget.snapshot!.data!.destination) {
        destination = widget.snapshot!.data!.destination;
      }
    }
    return destination;
  }

  void _trackPayment(String? destination) {
    final inputCubit = context.read<InputCubit>();
    inputCubit.trackPayment(destination).then((value) {
      Timer(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _onPaymentFinished(true);
        }
      });
    }).catchError((e) {
      _log.warning("Failed to track payment", e);
      if (mounted) {
        showFlushbar(context, message: extractExceptionMessage(e, context.texts()));
      }
      _onPaymentFinished(false);
    });
  }

  void _onPaymentFinished(dynamic result) {
    _log.info("Payment finished: $result");
    if (result == true) {
      // Close the page and show successful payment route
      if (mounted) {
        final navigatorState = Navigator.of(context);
        navigatorState.pop();
        navigatorState.push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => const SuccessfulPaymentRoute(),
          ),
        );
      }
    } else {
      if (result is String) {
        showFlushbar(context, title: "", message: result);
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
