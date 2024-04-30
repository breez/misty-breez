import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

abstract class Notifications {
  Future<String?> getToken();
  Stream<Map<dynamic, dynamic>> get notifications;
}

class FirebaseNotifications implements Notifications {
  final _log = Logger("FirebaseNotifications");

  FirebaseMessaging get _firebaseMessaging {
    return FirebaseMessaging.instance;
  }

  final StreamController<Map<dynamic, dynamic>> _notificationController =
      BehaviorSubject<Map<dynamic, dynamic>>();
  @override
  Stream<Map<dynamic, dynamic>> get notifications => _notificationController.stream;

  FirebaseNotifications() {
    FirebaseMessaging.onMessage.listen(_onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onResume);
  }

  Future _onMessage(RemoteMessage message) {
    _log.info("_onMessage = ${message.data}");
    var data = message.data["data"] ?? message.data["aps"] ?? message.data;
    if (data != null) {
      if (data is String) data = json.decode(data);
      _notificationController.add(data);
    }
    return Future.value(null);
  }

  Future _onResume(RemoteMessage message) {
    _log.info("_onResume = ${message.data}");
    var data = message.data["data"] ?? message.data;
    if (data != null) {
      if (data is String) data = json.decode(data);
      _notificationController.add(data);
    }
    return Future.value(null);
  }

  @override
  Future<String?> getToken() async {
    _log.info("getToken");
    NotificationSettings firebaseNotificationSettings = await _firebaseMessaging.requestPermission(
      sound: true,
      badge: true,
      alert: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    _log.config('User granted permission: ${firebaseNotificationSettings.authorizationStatus}');
    if (firebaseNotificationSettings.authorizationStatus == AuthorizationStatus.authorized) {
      _log.info("Authorized to get token");
      return _firebaseMessaging.getToken();
    } else {
      _log.warning("Unauthorized to get token");
      return null;
    }
  }
}
