class WebhookState {
  final String? lnurlPayUrl;
  final String? lnurlPayError;
  final bool isLoading;

  WebhookState({
    this.lnurlPayUrl,
    this.lnurlPayError,
    this.isLoading = false,
  });

  WebhookState copyWith({
    String? lnurlPayUrl,
    String? lnurlPayError,
    bool? isLoading,
  }) {
    return WebhookState(
      lnurlPayUrl: lnurlPayUrl ?? this.lnurlPayUrl,
      lnurlPayError: lnurlPayError ?? this.lnurlPayError,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AddWebhookRequest {
  final int time;
  final String webhookUrl;
  final String signature;

  AddWebhookRequest({
    required this.time,
    required this.webhookUrl,
    required this.signature,
  });

  Map<String, dynamic> toJson() => {
        'time': time,
        'webhook_url': webhookUrl,
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

  Map<String, dynamic> toJson() => {
        'time': time,
        'webhook_url': webhookUrl,
        'signature': signature,
      };
}
