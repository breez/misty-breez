import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:provider/provider.dart';

final Logger _logger = Logger('ProcessingPaymentSheet');

Future<dynamic> showProcessingPaymentSheet(
  BuildContext context, {
  required Future<dynamic> Function() paymentFunc,
  bool promptError = false,
  bool popToHomeOnCompletion = true,
  bool isLnPayment = false,
  bool isLnUrlPayment = false,
  bool isBroadcast = false,
}) async {
  return await showModalBottomSheet(
    context: context,
    isDismissible: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => ProcessingPaymentSheet(
      isLnPayment: isLnPayment,
      isLnUrlPayment: isLnUrlPayment,
      isBroadcast: isBroadcast,
      promptError: promptError,
      popToHomeOnCompletion: popToHomeOnCompletion,
      paymentFunc: paymentFunc,
    ),
  );
}

class ProcessingPaymentSheet extends StatefulWidget {
  final bool isLnPayment;
  final bool isLnUrlPayment;
  final bool isBroadcast;
  final bool promptError;
  final bool popToHomeOnCompletion;
  final Future<dynamic> Function() paymentFunc;

  const ProcessingPaymentSheet({
    required this.paymentFunc,
    this.promptError = false,
    this.popToHomeOnCompletion = true,
    this.isLnPayment = false,
    this.isLnUrlPayment = false,
    this.isBroadcast = false,
    super.key,
  });

  @override
  ProcessingPaymentSheetState createState() => ProcessingPaymentSheetState();
}

class ProcessingPaymentSheetState extends State<ProcessingPaymentSheet> {
  StreamSubscription<Payment>? _trackPaymentEventsSubscription;

  static const Duration timeoutDuration = Duration(seconds: 30);

  bool _showPaymentSent = false;

  @override
  void initState() {
    super.initState();
    _processPaymentAndClose();
  }

  @override
  void dispose() {
    _trackPaymentEventsSubscription?.cancel();
    super.dispose();
  }

  void _processPaymentAndClose() {
    widget.paymentFunc().then(_handlePaymentSuccess).catchError(_handlePaymentError);
  }

  void _handlePaymentSuccess(dynamic payResult) {
    if (!mounted) {
      return;
    }

    if (widget.isLnPayment) {
      _handleLnPaymentResult(payResult);
    } else if (widget.isLnUrlPayment) {
      _handleLnUrlPaymentResult(payResult);
    } else {
      _closeSheetOnCompletion();
    }
  }

  void _handleLnPaymentResult(dynamic payResult) {
    if (payResult is SendPaymentResponse) {
      _trackLnPaymentEvents(payResult);
    } else {
      _onPaymentFailure();
    }
  }

  void _handleLnUrlPaymentResult(dynamic payResult) {
    if (payResult is LnUrlPayResult_EndpointSuccess) {
      _showSuccessAndClose(payResult);
    } else {
      _onPaymentFailure();
    }
  }

  void _trackLnPaymentEvents(SendPaymentResponse payResult) {
    final Completer<bool> paymentCompleter = Completer<bool>();

    if (payResult.payment.details is PaymentDetails_Liquid) {
      _handleLiquidPayment(payResult, paymentCompleter);
    } else {
      _handleLnPayment(payResult, paymentCompleter);
    }

    // Wait at least 30 seconds for PaymentSucceeded event for LN payments, then show payment success sheet.
    final Future<void> timeoutFuture = Future<void>.delayed(timeoutDuration);
    Future.any(<Future<bool>>[paymentCompleter.future, timeoutFuture.then((_) => false)])
        .then((bool paymentSucceeded) {
          if (!mounted) {
            return;
          }

          if (paymentSucceeded) {
            _showSuccessAndClose();
          } else {
            _closeSheetOnCompletion();
          }
        })
        .catchError((_) {
          if (mounted) {
            _onPaymentFailure();
          }
        });
  }

  void _handleLiquidPayment(SendPaymentResponse payResult, Completer<bool> paymentCompleter) {
    final PaymentState paymentStatus = payResult.payment.status;
    if (paymentStatus == PaymentState.pending || paymentStatus == PaymentState.complete) {
      final String? paymentDestination = payResult.payment.destination;
      _logger.info(
        'Payment sent!${paymentDestination?.isNotEmpty == true ? ' Destination: $paymentDestination' : ''}',
      );
      paymentCompleter.complete(true);
    } else {
      _logger.warning('Payment failed! Status: $paymentStatus');
      paymentCompleter.complete(false);
    }
  }

  void _handleLnPayment(SendPaymentResponse payResult, Completer<bool> paymentCompleter) {
    final PaymentsCubit paymentsCubit = context.read<PaymentsCubit>();
    _trackPaymentEventsSubscription?.cancel();

    final String? expectedDestination = payResult.payment.destination;
    _logger.info('Tracking outgoing payments for destination: $expectedDestination');

    _trackPaymentEventsSubscription = paymentsCubit.trackPaymentEvents(
      paymentFilter: (Payment p) =>
          p.paymentType == PaymentType.send &&
          p.destination == expectedDestination &&
          p.status == PaymentState.complete,
      onData: (Payment p) {
        final String? paymentDestination = p.destination;
        _logger.info(
          'Outgoing payment detected!${paymentDestination?.isNotEmpty == true ? ' Destination: $paymentDestination' : ''}',
        );
        paymentCompleter.complete(true);
      },
      onError: (Object e) {
        _logger.warning('Failed to track outgoing payments.', e);
        paymentCompleter.complete(false);
      },
    );
  }

  void _showSuccessAndClose([dynamic payResult]) {
    if (!mounted) {
      return;
    }

    setState(() {
      _showPaymentSent = true;
    });
    // Close the bottom sheet after 2.25 seconds
    Future<void>.delayed(PaymentSheetTiming.popDelay, () {
      if (mounted) {
        if (payResult == null) {
          _closeSheetOnCompletion();
        } else {
          Navigator.of(context).pop(payResult);
        }
      }
    });
  }

  void _closeSheetOnCompletion() {
    final NavigatorState navigator = Navigator.of(context);
    if (widget.popToHomeOnCompletion) {
      navigator.pushNamedAndRemoveUntil(Home.routeName, (Route<dynamic> route) => false);
    } else {
      navigator.pop();
    }
  }

  void _handlePaymentError(Object err) {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(err);
    final BreezTranslations texts = getSystemAppLocalizations();

    if (widget.promptError) {
      _promptErrorDialog(err, texts);
      // TODO(erdemyerebasmaz): PaymentError::Generic is added because timeouts by Boltz are currently thrown as PaymentError::Generic by the SDK.
    } else if (err is FrbException || err is PaymentError_PaymentTimeout || err is PaymentError_Generic) {
      _showErrorFlushbar(err, texts);
    }
  }

  void _onPaymentFailure() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    showFlushbar(context, message: getSystemAppLocalizations().payment_error_to_send_unknown_reason);
  }

  void _promptErrorDialog(Object err, BreezTranslations texts) {
    final ThemeData themeData = Theme.of(context);
    promptError(
      context,
      title: texts.payment_failed_report_dialog_title,
      body: Text(ExceptionHandler.extractMessage(err, texts), style: themeData.dialogTheme.contentTextStyle),
    );
  }

  void _showErrorFlushbar(Object err, BreezTranslations texts) {
    final String message = ExceptionHandler.extractMessage(err, texts);
    showFlushbar(context, message: texts.payment_error_to_send(message));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: themeData.customData.paymentListBgColorLight,
      child: _showPaymentSent
          ? const PaymentSentContent()
          : ProcessingPaymentContent(isBroadcast: widget.isBroadcast, onClose: _closeSheetOnCompletion),
    );
  }
}
