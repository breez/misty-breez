import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/exceptions/exception_handler.dart';
import 'package:misty_breez/widgets/widgets.dart';

export 'widgets/widgets.dart';

final Logger _logger = Logger('DestinationWidget');

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
  StreamSubscription<Payment>? _trackIncomingPaymentsSubscription;

  Future<void> _trackIncomingPayments() async {
    final PaymentsCubit paymentsCubit = context.read<PaymentsCubit>();
    _trackIncomingPaymentsSubscription?.cancel();

    final PaymentTrackingConfig? trackingConfig = await _buildTrackingConfig();

    if (trackingConfig == null) {
      _logger.warning('Skipping tracking payment events.');
      return;
    }

    _trackIncomingPaymentsSubscription = await paymentsCubit.trackIncomingPayments(
      trackingConfig: trackingConfig,
      onData: _onTrackPaymentSucceed,
      onError: _onTrackPaymentError,
    );
  }

  Future<PaymentTrackingConfig?> _buildTrackingConfig() async {
    if (widget.lnAddress != null) {
      _logger.info('Tracking incoming payments to Lightning Address.');
      return PaymentTrackingConfig(lnAddress: widget.lnAddress);
    }

    if (widget.destination != null) {
      _logger.info(
        'Tracking incoming ${widget.isBitcoinPayment ? 'BTC' : 'LN'} payments to destination: ${widget.destination}',
      );
      return PaymentTrackingConfig(
        expectedDestination: widget.destination,
        isBitcoinPayment: widget.isBitcoinPayment,
      );
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
    _trackIncomingPayments();
  }

  @override
  void dispose() {
    _cancelTrackingIncomingPayments();
    super.dispose();
  }

  Future<void> _cancelTrackingIncomingPayments() async {
    if (_trackIncomingPaymentsSubscription != null) {
      await _trackIncomingPaymentsSubscription?.cancel();
      _logger.info('Cancelled tracking incoming payments for ${widget.paymentLabel}.');
    }
  }

  void _onPaymentFinished(bool isSuccess) {
    if (!mounted) {
      return;
    }
    _cancelTrackingIncomingPayments();
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
