class RegisterWebhookException implements Exception {
  final String message;

  RegisterWebhookException(this.message);

  @override
  String toString() => message;
}

class UnregisterWebhookException implements Exception {
  final String message;

  UnregisterWebhookException(this.message);

  @override
  String toString() => message;
}
