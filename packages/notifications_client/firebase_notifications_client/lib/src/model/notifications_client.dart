abstract class NotificationsClient {
  Future<String?> getToken();
  Stream<Map<dynamic, dynamic>> get notifications;
}
