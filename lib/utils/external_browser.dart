import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:l_breez/widgets/loader.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher_string.dart';

final _log = Logger("ExternalBrowser");

Future<void> launchLinkOnExternalBrowser(
  BuildContext context, {
  required String linkAddress,
}) async {
  final texts = context.texts();
  final themeData = Theme.of(context);
  final navigator = Navigator.of(context);
  var loaderRoute = createLoaderRoute(context);
  navigator.push(loaderRoute);
  try {
    if (await canLaunchUrlString(linkAddress)) {
      await ChromeSafariBrowser().open(
        url: WebUri(linkAddress),
        settings: ChromeSafariBrowserSettings(
          // Android
          shareState: CustomTabsShareState.SHARE_STATE_ON,
          showTitle: true,
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
    _log.warning(error.toString(), error);
    rethrow;
  } finally {
    navigator.removeRoute(loaderRoute);
  }
}
