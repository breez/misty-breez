import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_notifications_client/src/model/notifications_client.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

export 'package:firebase_notifications_client/src/model/notifications_client.dart';

final _log = Logger("FirebaseNotifications");

class FirebaseNotificationsClient implements NotificationsClient {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final _notificationController = BehaviorSubject<Map<dynamic, dynamic>>();

  @override
  Stream<Map<dynamic, dynamic>> get notifications => _notificationController.stream;

  FirebaseNotificationsClient() {
    FirebaseMessaging.onMessage.listen(_onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onResume);
  }

  Future<void> _onMessage(RemoteMessage message) async {
    _log.info("_onMessage = ${message.data}");
    final data = _extractData(message.data);
    if (data != null) {
      _notificationController.add(data);
    }
  }

  Future<void> _onResume(RemoteMessage message) async {
    _log.info("_onResume = ${message.data}");
    final data = _extractData(message.data);
    if (data != null) {
      _notificationController.add(data);
    }
  }

  Map<dynamic, dynamic>? _extractData(Map<String, dynamic> data) {
    var extractedData = data["data"] ?? data["aps"] ?? data;
    if (extractedData is String) {
      extractedData = json.decode(extractedData);
    }
    return extractedData;
  }

  @override
  Future<String?> getToken() async {
    _log.info("getToken");
    final firebaseNotificationSettings = await _firebaseMessaging.requestPermission(
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
