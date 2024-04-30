import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uni_links/uni_links.dart';

class LightningLinksService {
  final _log = Logger("LightningLinksService");
  final StreamController<String> _linksNotificationsController = BehaviorSubject<String>();

  Stream<String> get linksNotifications => _linksNotificationsController.stream;

  LightningLinksService() {
    Rx.merge([
      getInitialLink().asStream(),
      linkStream,
    ]).where(_canHandle).listen((l) {
      _log.info("Got lightning link: $l");
      if (l!.startsWith("breez:")) {
        l = l.substring(6);
      }
      _linksNotificationsController.add(l);
    });
  }

  bool _canHandle(String? link) {
    if (link == null) return false;
    return link.startsWith("breez:") ||
        link.startsWith("lightning:") ||
        link.startsWith("lnurlc:") ||
        link.startsWith("lnurlp:") ||
        link.startsWith("lnurlw:") ||
        link.startsWith("keyauth:");
  }

  close() {
    _linksNotificationsController.close();
  }
}
