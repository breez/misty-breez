class WebhookState {
  final String? lnurlPayUrl;
  final String? lnurlPayError;
  final String? lnurlPayErrorTitle;
  final bool isLoading;

  WebhookState({
    this.lnurlPayUrl,
    this.lnurlPayError,
    this.lnurlPayErrorTitle,
    this.isLoading = false,
  });

  WebhookState copyWith({
    String? lnurlPayUrl,
    String? lnurlPayError,
    String? lnurlPayErrorTitle,
    bool? isLoading,
  }) {
    return WebhookState(
      lnurlPayUrl: lnurlPayUrl ?? this.lnurlPayUrl,
      lnurlPayError: lnurlPayError ?? this.lnurlPayError,
      lnurlPayErrorTitle: lnurlPayErrorTitle ?? this.lnurlPayErrorTitle,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AddWebhookRequest {
  final int time;
  final String webhookUrl;
  final String? username;
  final String signature;

  AddWebhookRequest({
    required this.time,
    required this.webhookUrl,
    required this.username,
    required this.signature,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'time': time,
        'webhook_url': webhookUrl,
        'username': username,
        'signature': signature,
      };
}

class RemoveWebhookRequest {
  final int time;
  final String webhookUrl;
  final String signature;

  RemoveWebhookRequest({
    required this.time,
    required this.webhookUrl,
    required this.signature,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'time': time,
        'webhook_url': webhookUrl,
        'signature': signature,
      };
}
