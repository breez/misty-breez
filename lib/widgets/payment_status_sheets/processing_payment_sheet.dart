import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/services/services.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:provider/provider.dart';

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
  late final PaymentTrackingService paymentTrackingService;

  static const Duration timeoutDuration = Duration(seconds: 30);

  bool _showPaymentSent = false;

  @override
  void initState() {
    super.initState();
    paymentTrackingService = Provider.of<PaymentTrackingService>(context, listen: false);
    _processPaymentAndClose();
  }

  @override
  void dispose() {
    paymentTrackingService.dispose();
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
    final Completer<void> paymentCompleter = Completer<void>();

    final PaymentTrackingConfig config = PaymentTrackingConfig.send(
      destination: payResult.payment.destination,
      onPaymentComplete: (bool success) {
        if (success) {
          paymentCompleter.complete();
        } else {
          paymentCompleter.completeError('Payment failed');
        }
      },
    );
    paymentTrackingService.startTracking(config: config);

    final Future<void> paymentSuccessFuture = paymentCompleter.future;

    // Wait at least 30 seconds for PaymentSucceeded event for LN payments, then show payment success sheet.
    final Future<void> timeoutFuture = Future<void>.delayed(timeoutDuration);
    Future.any(<Future<bool>>[
      paymentSuccessFuture.then((_) => true),
      timeoutFuture.then((_) => false),
    ]).then((bool paymentSucceeded) {
      if (!mounted) {
        return;
      }

      if (paymentSucceeded) {
        _showSuccessAndClose();
      } else {
        _closeSheetOnCompletion();
      }
    }).catchError((_) {
      if (mounted) {
        _onPaymentFailure();
      }
    });
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
    } else if (err is FrbException || err is PaymentError_PaymentTimeout) {
      _showErrorFlushbar(err, texts);
    }
  }

  void _onPaymentFailure() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    showFlushbar(
      context,
      message: getSystemAppLocalizations().payment_error_to_send_unknown_reason,
    );
  }

  void _promptErrorDialog(Object err, BreezTranslations texts) {
    final ThemeData themeData = Theme.of(context);
    promptError(
      context,
      title: texts.payment_failed_report_dialog_title,
      body: Text(
        ExceptionHandler.extractMessage(err, texts),
        style: themeData.dialogTheme.contentTextStyle,
      ),
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
          : ProcessingPaymentContent(
              isBroadcast: widget.isBroadcast,
              onClose: _closeSheetOnCompletion,
            ),
    );
  }
}
