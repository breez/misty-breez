import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/utils/exceptions.dart';

class LNURLPageResult {
  final LnUrlProtocol? protocol;
  final SuccessActionProcessed? successAction;
  final Object? error;

  const LNURLPageResult({
    this.protocol,
    this.successAction,
    this.error,
  });

  bool get hasError => error != null;

  String get errorMessage => extractExceptionMessage(
        error ?? "",
        getSystemAppLocalizations(),
        defaultErrorMsg: getSystemAppLocalizations().lnurl_payment_page_unknown_error,
      );

  @override
  String toString() {
    return 'LNURLPageResult{protocol: $protocol, successAction: $successAction, error: $error}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LNURLPageResult &&
          runtimeType == other.runtimeType &&
          protocol == other.protocol &&
          successAction == other.successAction &&
          error == other.error;

  @override
  int get hashCode => protocol.hashCode ^ successAction.hashCode ^ error.hashCode;
}

// Supported LNURL specs
enum LnUrlProtocol { auth, pay, withdraw }
