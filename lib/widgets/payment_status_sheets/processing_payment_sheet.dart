import 'dart:async';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/widgets.dart';

Future<dynamic> showProcessingPaymentSheet(
  BuildContext context, {
  required Future<dynamic> Function() paymentFunc,
  bool promptError = false,
  bool popToHomeOnCompletion = false,
  bool isLnPayment = false,
  bool isLnUrlPayment = false,
}) async {
  return await showModalBottomSheet(
    context: context,
    isDismissible: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) => ProcessingPaymentSheet(
      isLnPayment: isLnPayment,
      isLnUrlPayment: isLnUrlPayment,
      promptError: promptError,
      popToHomeOnCompletion: popToHomeOnCompletion,
      paymentFunc: paymentFunc,
    ),
  );
}

class ProcessingPaymentSheet extends StatefulWidget {
  final bool isLnPayment;
  final bool isLnUrlPayment;
  final bool promptError;
  final bool popToHomeOnCompletion;
  final Future<dynamic> Function() paymentFunc;

  const ProcessingPaymentSheet({
    required this.paymentFunc,
    this.promptError = false,
    this.popToHomeOnCompletion = false,
    this.isLnPayment = false,
    this.isLnUrlPayment = false,
    super.key,
  });

  @override
  ProcessingPaymentSheetState createState() => ProcessingPaymentSheetState();
}

class ProcessingPaymentSheetState extends State<ProcessingPaymentSheet> {
  bool _showPaymentSent = false;

  @override
  void initState() {
    super.initState();
    _processPaymentAndClose();
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
    final InputCubit inputCubit = context.read<InputCubit>();

    final Future<void> paymentSuccessFuture = inputCubit.trackPaymentEvents(
      payResult.payment.destination,
      paymentType: PaymentType.send,
    );
    final Future<void> timeoutFuture = Future<void>.delayed(const Duration(seconds: 10));

    // Wait at least 10 seconds for PaymentSucceeded event for LN payments, then show payment success sheet.
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

    setState(() => _showPaymentSent = true);
    Future<void>.delayed(const Duration(milliseconds: 2250), () {
      if (mounted) {
        Navigator.of(context).pop(payResult);
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
    final ThemeData theme = Theme.of(context);
    promptError(
      context,
      texts.payment_failed_report_dialog_title,
      Text(
        extractExceptionMessage(err, texts),
        style: theme.dialogTheme.contentTextStyle,
      ),
    );
  }

  void _showErrorFlushbar(Object err, BreezTranslations texts) {
    final String message = extractExceptionMessage(err, texts);
    showFlushbar(context, message: texts.payment_error_to_send(message));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: themeData.colorScheme.surface,
      child: _showPaymentSent ? const PaymentSentContent() : const ProcessingPaymentContent(),
    );
  }
}
