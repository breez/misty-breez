import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/services/services.dart';
import 'package:misty_breez/widgets/widgets.dart';
import 'package:provider/provider.dart';

export 'login_text.dart';

final Logger _logger = Logger('HandleLNURLAuthRequest');

Future<LNURLPageResult?> handleAuthRequest(
  BuildContext context,
  LnUrlAuthRequestData reqData,
) async {
  return promptAreYouSure(context, body: LoginText(domain: reqData.domain)).then(
    (bool? permitted) async {
      if (permitted == true && context.mounted) {
        final BreezTranslations texts = context.texts();
        final NavigatorState navigator = Navigator.of(context);
        final TransparentPageRoute<void> loaderRoute = createLoaderRoute(context);
        navigator.push(loaderRoute);
        try {
          final LnUrlService lnUrlService = Provider.of<LnUrlService>(context);
          final LnUrlCallbackStatus resp = await lnUrlService.lnurlAuth(reqData: reqData);
          if (resp is LnUrlCallbackStatus_Ok) {
            _logger.info('LNURL auth success');
            return const LNURLPageResult(protocol: LnUrlProtocol.auth);
          } else if (resp is LnUrlCallbackStatus_ErrorStatus) {
            _logger.info('LNURL auth failed: ${resp.data.reason}');
            return LNURLPageResult(protocol: LnUrlProtocol.auth, error: resp.data.reason);
          } else {
            _logger.warning('Unknown response from lnurlAuth: $resp');
            return LNURLPageResult(
              protocol: LnUrlProtocol.auth,
              error: texts.lnurl_payment_page_unknown_error,
            );
          }
        } catch (e) {
          _logger.warning('Error authenticating LNURL auth', e);
          if (loaderRoute.isActive) {
            navigator.removeRoute(loaderRoute);
          }
          return LNURLPageResult(protocol: LnUrlProtocol.auth, error: e);
        } finally {
          if (loaderRoute.isActive) {
            navigator.removeRoute(loaderRoute);
          }
        }
      }
      return Future<LNURLPageResult?>.value();
    },
  );
}

void handleLNURLAuthPageResult(BuildContext context, LNURLPageResult result) {
  if (result.hasError) {
    _logger.info("Handle LNURL auth page result with error '${result.error}'");
    promptError(
      context,
      title: context.texts().lnurl_webview_error_title,
      body: Text(result.errorMessage),
    );
    throw result.error!;
  }
}
