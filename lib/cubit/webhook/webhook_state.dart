class WebhookState {
  final String? lnurlPayUrl;
  final String? lnAddress;
  final String? lnAddressUsername;
  final String? webhookError;
  final String? webhookErrorTitle;
  final String? lnurlPayError;
  final String? lnurlPayErrorTitle;
  final bool isLoading;

  WebhookState({
    this.lnurlPayUrl,
    this.lnAddress,
    this.lnAddressUsername,
    this.webhookError,
    this.webhookErrorTitle,
    this.lnurlPayError,
    this.lnurlPayErrorTitle,
    this.isLoading = false,
  });

  WebhookState copyWith({
    String? lnurlPayUrl,
    String? lnAddress,
    String? webhookError,
    String? webhookErrorTitle,
    String? lnurlPayError,
    String? lnurlPayErrorTitle,
    bool? isLoading,
  }) {
    return WebhookState(
      lnurlPayUrl: lnurlPayUrl ?? this.lnurlPayUrl,
      lnAddress: lnAddress ?? this.lnAddress,
      webhookError: webhookError ?? this.webhookError,
      webhookErrorTitle: webhookErrorTitle ?? this.webhookErrorTitle,
      lnurlPayError: lnurlPayError ?? this.lnurlPayError,
      lnurlPayErrorTitle: lnurlPayErrorTitle ?? this.lnurlPayErrorTitle,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() {
    return 'WebhookState('
        'lnurlPayUrl: $lnurlPayUrl, '
        'lnAddress: $lnAddress, '
        'webhookError: $webhookError, '
        'webhookErrorTitle: $webhookErrorTitle, '
        'lnurlPayError: $lnurlPayError, '
        'lnurlPayErrorTitle: $lnurlPayErrorTitle, '
        'isLoading: $isLoading)';
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
