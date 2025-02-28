/// Container for signed request data components.
///
/// Used internally to hold common data needed for different request types.
class SignedRequestData {
  /// Unix timestamp in seconds
  final int timestamp;

  /// Cryptographic signature of the message
  final String signature;

  /// Creates a new SignedRequestData instance.
  SignedRequestData({
    required this.timestamp,
    required this.signature,
  });
}
