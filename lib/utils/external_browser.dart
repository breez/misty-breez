import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:l_breez/widgets/transparent_page_route.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher_string.dart';

final Logger _logger = Logger('ExternalBrowser');

Future<void> launchLinkOnExternalBrowser(
  BuildContext context, {
  required String linkAddress,
}) async {
  final BreezTranslations texts = context.texts();
  final ThemeData themeData = Theme.of(context);
  final NavigatorState navigator = Navigator.of(context);
  final TransparentPageRoute<void> loaderRoute = createLoaderRoute(context);
  navigator.push(loaderRoute);
  try {
    if (await canLaunchUrlString(linkAddress)) {
      await ChromeSafariBrowser().open(
        url: WebUri(linkAddress),
        settings: ChromeSafariBrowserSettings(
          // Android
          shareState: CustomTabsShareState.SHARE_STATE_ON,
          // iOS
          dismissButtonStyle: DismissButtonStyle.CLOSE,
          barCollapsingEnabled: true,
          // Styling
          // Android
          toolbarBackgroundColor: themeData.appBarTheme.backgroundColor,
          navigationBarColor: themeData.bottomAppBarTheme.color,
          // iOS 10.0+
          preferredControlTintColor: Colors.white,
          preferredBarTintColor: themeData.appBarTheme.backgroundColor,
        ),
      );
    } else {
      throw Exception(texts.link_launcher_failed_to_launch(linkAddress));
    }
  } catch (error) {
    _logger.warning(error.toString(), error);
    rethrow;
  } finally {
    navigator.removeRoute(loaderRoute);
  }
}
