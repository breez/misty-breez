import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uni_links/uni_links.dart';

final _log = Logger("LightningLinksService");

class LightningLinksService {
  final _linksNotificationsController = BehaviorSubject<String>();
  Stream<String> get linksNotifications => _linksNotificationsController.stream;

  LightningLinksService() {
    _initializeLinkHandling();
  }

  void _initializeLinkHandling() {
    Rx.merge([
      getInitialLink().asStream(),
      linkStream,
    ]).where((link) => _isValidLink(link)).listen((link) => _handleLink(link));
  }

  bool _isValidLink(String? link) {
    if (link == null) return false;
    const validPrefixes = [
      "breez:",
      "lightning:",
      "lnurlc:",
      "lnurlp:",
      "lnurlw:",
      "keyauth:",
    ];
    return validPrefixes.any(link.startsWith);
  }

  void _handleLink(String? link) {
    if (link == null) return;
    _log.info("Got lightning link: $link");
    if (link.startsWith("breez:")) {
      link = link.substring(6);
    }
    _linksNotificationsController.add(link);
  }

  void close() {
    _linksNotificationsController.close();
  }
}
