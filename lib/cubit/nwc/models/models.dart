class RegisterNwcWebhookRequest {
  final String webhookUrl;
  final String? walletServicePubkey;
  final String? appPubkey;
  final List<String>? relays;
  final String signature;

  const RegisterNwcWebhookRequest({
    required this.webhookUrl,
    required this.walletServicePubkey,
    required this.appPubkey,
    required this.relays,
    required this.signature,
  });

  RegisterNwcWebhookRequest copyWith({
    String? webhookUrl,
    String? appPubkey,
    String? walletServicePubkey,
    List<String>? relays,
    String? signature,
  }) {
    return RegisterNwcWebhookRequest(
      webhookUrl: webhookUrl ?? this.webhookUrl,
      appPubkey: appPubkey ?? this.appPubkey,
      walletServicePubkey: walletServicePubkey ?? this.walletServicePubkey,
      relays: relays ?? this.relays,
      signature: signature ?? this.signature,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'webhookUrl': webhookUrl,
      'walletServicePubkey': walletServicePubkey,
      'appPubkey': appPubkey,
      'relays': relays,
      'signature': signature,
    };
  }

  @override
  String toString() =>
      'webhookUrl=$webhookUrl, appPubkey=$appPubkey, walletServicePubkey=$walletServicePubkey, relays=$relays, signature=$signature';
}

class UnregisterNwcWebhookRequest {
  final int time;
  final String walletServicePubkey;
  final String appPubkey;
  final String signature;

  const UnregisterNwcWebhookRequest({
    required this.time,
    required this.walletServicePubkey,
    required this.appPubkey,
    required this.signature,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'time': time,
      'walletServicePubkey': walletServicePubkey,
      'appPubkey': appPubkey,
      'signature': signature,
    };
  }

  @override
  String toString() =>
      'time=$time, walletServicePubkey=$walletServicePubkey, appPubkey=$appPubkey, signature=$signature';
}
