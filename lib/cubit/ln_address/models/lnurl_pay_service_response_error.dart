/// Represents an HTTP response error returned from an LnUrl Pay Service endpoint.
class LnurlPayServiceResponseError {
  final int statusCode;
  final String body;

  LnurlPayServiceResponseError(this.statusCode, this.body);
}
