class RegisterNwcWebhookRequest {
  final String webhookUrl;
  final String? appPubkey;
  final List<String>? relays;
  final String signature;

  const RegisterNwcWebhookRequest({
    required this.webhookUrl,
    required this.appPubkey,
    required this.relays,
    required this.signature,
  });

  RegisterNwcWebhookRequest copyWith({
    String? webhookUrl,
    String? appPubkey,
    List<String>? relays,
    String? signature,
  }) {
    return RegisterNwcWebhookRequest(
      webhookUrl: webhookUrl ?? this.webhookUrl,
      appPubkey: appPubkey ?? this.appPubkey,
      relays: relays ?? this.relays,
      signature: signature ?? this.signature,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'webhook_url': webhookUrl,
      'app_pubkey': appPubkey,
      'relays': relays,
      'signature': signature,
    };
  }

  @override
  String toString() => 'webhook_url=$webhookUrl, app_pubkey=$appPubkey, relays=$relays, signature=$signature';
}

class UnregisterNwcWebhookRequest {
  final int time;
  final String appPubkey;
  final String signature;

  const UnregisterNwcWebhookRequest({required this.time, required this.appPubkey, required this.signature});

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'time': time, 'app_pubkey': appPubkey, 'signature': signature};
  }

  @override
  String toString() => 'time=$time, app_pubkey=$appPubkey, signature=$signature';
}
