class RegisterLnurlPayException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  RegisterLnurlPayException(this.message, {this.statusCode, this.responseBody});

  @override
  String toString() =>
      'RegisterLnurlPayException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class UnregisterLnurlPayException implements Exception {
  final String message;

  UnregisterLnurlPayException(this.message);

  @override
  String toString() => message;
}

class UsernameConflictException implements Exception {
  @override
  String toString() => 'Username is already taken';
}

class MaxRetriesExceededException implements Exception {
  @override
  String toString() => 'Maximum retry attempts exceeded';
}

class GenerateWebhookUrlException implements Exception {
  final String message;

  GenerateWebhookUrlException(this.message);

  @override
  String toString() => message;
}

class RegisterWebhookException implements Exception {
  final String message;

  RegisterWebhookException(this.message);

  @override
  String toString() => message;
}
