class GenerateWebhookException implements Exception {
  final String message;
  GenerateWebhookException(this.message);
  @override
  String toString() => message;
}

class WebhookRegistrationException implements Exception {
  final String message;
  WebhookRegistrationException(this.message);
  @override
  String toString() => message;
}

class WebhookInvalidationException implements Exception {
  final String message;
  WebhookInvalidationException(this.message);
  @override
  String toString() => message;
}

class InvalidateWebhookException implements Exception {
  final String message;
  InvalidateWebhookException(this.message);
  @override
  String toString() => message;
}

class LnAddressRegistrationException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  LnAddressRegistrationException(this.message, {this.statusCode, this.responseBody});

  @override
  String toString() =>
      'LnAddressRegistrationException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class UsernameConflictException implements Exception {
  @override
  String toString() => 'Username is already taken';
}

class MaxRetriesExceededException implements Exception {
  @override
  String toString() => 'Maximum retry attempts exceeded';
}
