class RecoverLnurlPayException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  RecoverLnurlPayException(this.message, {this.statusCode, this.responseBody});

  @override
  String toString() =>
      'RecoverLnurlPayException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class WebhookNotFoundException implements Exception {
  @override
  String toString() => 'No associated webhook found for given public key.';
}

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
