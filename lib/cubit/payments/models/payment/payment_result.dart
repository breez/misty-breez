import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/utils/utils.dart';

class PaymentResult {
  final Payment? paymentInfo;
  final PaymentResultError? error;

  const PaymentResult({
    this.paymentInfo,
    this.error,
  });

  @override
  String toString() {
    return 'PaymentResult{paymentInfo: $paymentInfo, error: $error}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentResult &&
          runtimeType == other.runtimeType &&
          paymentInfo == other.paymentInfo &&
          error == other.error;

  @override
  int get hashCode => paymentInfo.hashCode ^ error.hashCode;
}

class PaymentResultError {
  final String message;
  final String paymentHash;
  final String comment;

  const PaymentResultError({
    required this.message,
    required this.paymentHash,
    required this.comment,
  });

  factory PaymentResultError.fromException(String paymentHash, Object? error, {BuildContext? context}) {
    final BreezTranslations texts = context?.texts() ?? getSystemAppLocalizations();
    final String? displayMessage = error != null ? ExceptionHandler.extractMessage(error, texts) : null;
    return PaymentResultError(
      message: displayMessage != null
          ? texts.payment_error_to_send(displayMessage)
          : texts.payment_error_to_send_unknown_reason,
      paymentHash: paymentHash,
      comment: error?.toString() ?? 'Unknown error',
    );
  }

  @override
  String toString() {
    return 'PaymentResultError{message: $message, paymentHash: $paymentHash, comment: $comment}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentResultError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          paymentHash == other.paymentHash &&
          comment == other.comment;

  @override
  int get hashCode => message.hashCode ^ paymentHash.hashCode ^ comment.hashCode;
}
