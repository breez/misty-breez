import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import "package:flutter_rust_bridge/flutter_rust_bridge.dart";
import 'package:logging/logging.dart';

final _log = Logger("Exceptions");

String extractExceptionMessage(
  Object exception,
  BreezTranslations texts, {
  String? defaultErrorMsg,
}) {
  _log.info("extractExceptionMessage: $exception");
  if (exception is AnyhowException) {
    if (exception.message.isNotEmpty) {
      var message = exception.message.replaceAll("\n", " ").trim();
      message = _extractInnerErrorMessage(message)?.trim() ?? message;
      message = _localizedExceptionMessage(texts, message);
      return message;
    }
  }
  if (exception is SdkError_Generic) {
    var message = exception.err.replaceAll("\n", " ").trim();
    message = _extractInnerErrorMessage(message)?.trim() ?? message;
    message = _localizedExceptionMessage(texts, message);
    return message;
  }
  if (exception is PaymentError_InsufficientFunds) {
    return texts.invoice_payment_validator_error_insufficient_local_balance;
  }
  return _extractInnerErrorMessage(exception.toString()) ?? defaultErrorMsg ?? exception.toString();
}

String? _extractInnerErrorMessage(String content) {
  _log.info("extractInnerErrorMessage: $content");
  final innerMessageRegex = RegExp(r'((?<=message: \\")(.*)(?=.*\\"))');
  final messageRegex = RegExp(r'((?<=message: ")(.*)(?=.*"))');
  final causedByRegex = RegExp(r'((?<=Caused by: )(.*)(?=.*))');
  final reasonRegex = RegExp(r'((?<=FAILURE_REASON_)(.*)(?=.*))');

  return innerMessageRegex.stringMatch(content) ??
      messageRegex.stringMatch(content) ??
      causedByRegex.stringMatch(content) ??
      reasonRegex.stringMatch(content);
}

String _localizedExceptionMessage(
  BreezTranslations texts,
  String originalMessage,
) {
  _log.info("localizedExceptionMessage: $originalMessage");
  final messageToLower = originalMessage.toLowerCase();
  if (messageToLower.contains("transport error")) {
    return texts.generic_network_error;
  } else if (messageToLower.contains("insufficient_balance")) {
    return texts.payment_error_insufficient_balance;
  } else if (messageToLower.contains("incorrect_payment_details")) {
    return texts.payment_error_incorrect_payment_details;
  } else if (messageToLower == "error") {
    return texts.payment_error_unexpected_error;
  } else if (messageToLower == "no_route") {
    return texts.payment_error_no_route;
  } else if (messageToLower == "timeout") {
    return texts.payment_error_payment_timeout_exceeded;
  } else if (messageToLower == "none") {
    return texts.payment_error_none;
  } else if (messageToLower.startsWith("lsp doesn't support opening a new channel")) {
    return texts.lsp_error_cannot_open_channel;
  } else if (messageToLower.contains("dns error") || messageToLower.contains("os error 104")) {
    return texts.generic_network_error;
  } else if (messageToLower.contains("mnemonic has an invalid checksum")) {
    return texts.enter_backup_phrase_error;
  } else {
    return originalMessage;
  }
}
