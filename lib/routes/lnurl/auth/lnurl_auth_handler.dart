import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/lnurl/auth/login_text.dart';
import 'package:l_breez/routes/lnurl/widgets/lnurl_page_result.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('HandleLNURLAuthRequest');

Future<LNURLPageResult?> handleAuthRequest(
  BuildContext context,
  LnUrlAuthRequestData reqData,
) async {
  return promptAreYouSure(context, null, LoginText(domain: reqData.domain)).then(
    (bool? permitted) async {
      if (permitted == true && context.mounted) {
        final BreezTranslations texts = context.texts();
        final NavigatorState navigator = Navigator.of(context);
        final TransparentPageRoute<void> loaderRoute = createLoaderRoute(context);
        navigator.push(loaderRoute);
        try {
          final LnUrlCubit lnurlCubit = context.read<LnUrlCubit>();
          final LnUrlCallbackStatus resp = await lnurlCubit.lnurlAuth(reqData: reqData);
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
      context.texts().lnurl_webview_error_title,
      Text(result.errorMessage),
      okFunc: () => Navigator.of(context).pop(),
    );
    throw result.error!;
  }
}
