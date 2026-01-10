class RegisterNwcWebhookRequest {
  final String webhookUrl;
  final String? userPubkey;
  final String? appPubkey;
  final List<String>? relays;
  final String signature;

  const RegisterNwcWebhookRequest({
    required this.webhookUrl,
    required this.userPubkey,
    required this.appPubkey,
    required this.relays,
    required this.signature,
  });

  RegisterNwcWebhookRequest copyWith({
    String? webhookUrl,
    String? appPubkey,
    String? userPubkey,
    List<String>? relays,
    String? signature,
  }) {
    return RegisterNwcWebhookRequest(
      webhookUrl: webhookUrl ?? this.webhookUrl,
      appPubkey: appPubkey ?? this.appPubkey,
      userPubkey: userPubkey ?? this.userPubkey,
      relays: relays ?? this.relays,
      signature: signature ?? this.signature,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'webhookUrl': webhookUrl,
      'userPubkey': userPubkey,
      'appPubkey': appPubkey,
      'relays': relays,
      'signature': signature,
    };
  }

  @override
  String toString() =>
      'webhookUrl=$webhookUrl, appPubkey=$appPubkey, userPubkey=$userPubkey, relays=$relays, signature=$signature';
}

class UnregisterNwcWebhookRequest {
  final int time;
  final String userPubkey;
  final String appPubkey;
  final String signature;

  const UnregisterNwcWebhookRequest({
    required this.time,
    required this.userPubkey,
    required this.appPubkey,
    required this.signature,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'time': time,
      'userPubkey': appPubkey,
      'appPubkey': appPubkey,
      'signature': signature,
    };
  }

  @override
  String toString() => 'time=$time, userPubkey=$userPubkey, appPubkey=$appPubkey, signature=$signature';
}
