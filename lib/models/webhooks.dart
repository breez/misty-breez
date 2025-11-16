class RegisterWebhookException implements Exception {
  final String message;

  RegisterWebhookException(this.message);

  @override
  String toString() => message;
}
