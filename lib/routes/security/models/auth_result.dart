/// Represents the result of a PIN code or biometric authentication attempt.
class AuthResult {
  /// Whether the authentication was successful.
  final bool success;

  /// Error message if authentication failed.
  final String? errorMessage;

  /// Whether to clear the PIN input field on success.
  final bool clearOnSuccess;

  /// Creates an authentication result.
  ///
  /// [success] Whether the authentication was successful.
  /// [errorMessage] Error message if authentication failed.
  /// [clearOnSuccess] Whether to clear the PIN input field on success.
  const AuthResult({
    required this.success,
    this.errorMessage,
    this.clearOnSuccess = false,
  });
}
