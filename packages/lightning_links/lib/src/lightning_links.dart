import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

final Logger _logger = Logger('LightningLinksService');

class LightningLinksService {
  final AppLinks appLinks = AppLinks();

  final BehaviorSubject<String> _linksNotificationsController = BehaviorSubject<String>();
  Stream<String> get linksNotifications => _linksNotificationsController.stream;

  LightningLinksService() {
    _initializeLinkHandling();
  }

  void _initializeLinkHandling() {
    Rx.merge(
      <Stream<String?>>[
        appLinks.getInitialLinkString().asStream(),
        appLinks.stringLinkStream,
      ],
    )
        .where(
          (String? link) => _isValidLink(link),
        )
        .listen(
          (String? link) => _handleLink(link),
        );
  }

  bool _isValidLink(String? link) {
    if (link == null) {
      return false;
    }
    const List<String> validPrefixes = <String>[
      'breez:',
      'lightning:',
      'lnurlc:',
      'lnurlp:',
      'lnurlw:',
      'keyauth:',
    ];
    return validPrefixes.any(link.startsWith);
  }

  void _handleLink(String? link) {
    if (link == null) {
      return;
    }
    _logger.info('Got lightning link: $link');
    if (link.startsWith('breez:')) {
      link = link.substring(6);
    }
    _linksNotificationsController.add(link);
  }

  void close() {
    _linksNotificationsController.close();
  }
}
