class RegisterLnurlPayRequest {
  final int time;
  final String webhookUrl;
  final String? username;
  final String? offer;
  final String signature;

  const RegisterLnurlPayRequest({
    required this.time,
    required this.webhookUrl,
    required this.username,
    required this.offer,
    required this.signature,
  });

  RegisterLnurlPayRequest copyWith({
    int? time,
    String? webhookUrl,
    String? username,
    String? offer,
    String? signature,
  }) {
    return RegisterLnurlPayRequest(
      time: time ?? this.time,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      username: username ?? this.username,
      offer: offer ?? this.offer,
      signature: signature ?? this.signature,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'time': time,
      'webhook_url': webhookUrl,
      'username': username,
      'offer': offer,
      'signature': signature,
    };
  }

  @override
  String toString() =>
      'username=$username, time=$time, webhook_url=$webhookUrl, offer=$offer, signature=$signature';
}

class RegisterRecoverLnurlPayResponse {
  final String lnurl;
  final String lightningAddress;

  const RegisterRecoverLnurlPayResponse({required this.lnurl, required this.lightningAddress});

  factory RegisterRecoverLnurlPayResponse.fromJson(Map<String, dynamic> json) {
    return RegisterRecoverLnurlPayResponse(
      lnurl: json['lnurl'] as String,
      lightningAddress: json['lightning_address'] as String? ?? '',
    );
  }

  @override
  String toString() => 'lnurl=$lnurl, lightning_address=$lightningAddress';
}

class UnregisterRecoverLnurlPayRequest {
  final int time;
  final String webhookUrl;
  final String signature;

  const UnregisterRecoverLnurlPayRequest({
    required this.time,
    required this.webhookUrl,
    required this.signature,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'time': time, 'webhook_url': webhookUrl, 'signature': signature};
  }

  @override
  String toString() => 'time=$time, webhook_url=$webhookUrl, signature=$signature';
}
