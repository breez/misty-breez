import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/bloc/account/account_bloc.dart';
import 'package:l_breez/routes/lnurl/auth/login_text.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_page_result.dart';
import 'package:l_breez/widgets/error_dialog.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

final _log = Logger("HandleLNURLAuthRequest");

Future<LNURLPageResult?> handleAuthRequest(
  BuildContext context,
  LnUrlAuthRequestData reqData,
) async {
  return promptAreYouSure(context, null, LoginText(domain: reqData.domain)).then(
    (permitted) async {
      if (permitted == true) {
        final texts = context.texts();
        final navigator = Navigator.of(context);
        final loaderRoute = createLoaderRoute(context);
        navigator.push(loaderRoute);
        try {
          final resp = await context.read<AccountBloc>().lnurlAuth(reqData: reqData);
          if (resp is LnUrlCallbackStatus_Ok) {
            _log.info("LNURL auth success");
            return const LNURLPageResult(protocol: LnUrlProtocol.Auth);
          } else if (resp is LnUrlCallbackStatus_ErrorStatus) {
            _log.info("LNURL auth failed: ${resp.data.reason}");
            return LNURLPageResult(protocol: LnUrlProtocol.Auth, error: resp.data.reason);
          } else {
            _log.warning("Unknown response from lnurlAuth: $resp");
            return LNURLPageResult(
              protocol: LnUrlProtocol.Auth,
              error: texts.lnurl_payment_page_unknown_error,
            );
          }
        } catch (e) {
          _log.warning("Error authenticating LNURL auth", e);
          if (loaderRoute.isActive) {
            navigator.removeRoute(loaderRoute);
          }
          return LNURLPageResult(protocol: LnUrlProtocol.Auth, error: e);
        } finally {
          if (loaderRoute.isActive) {
            navigator.removeRoute(loaderRoute);
          }
        }
      }
      return Future.value();
    },
  );
}

void handleLNURLAuthPageResult(BuildContext context, LNURLPageResult result) {
  if (result.hasError) {
    _log.info("Handle LNURL auth page result with error '${result.error}'");
    promptError(
      context,
      context.texts().lnurl_webview_error_title,
      Text(result.errorMessage),
      okFunc: () => Navigator.of(context).pop(),
    );
    throw result.error!;
  }
}
