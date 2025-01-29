class RegisterLnurlPayRequest {
  final String? username;
  final int time;
  final String webhookUrl;
  final String signature;

  const RegisterLnurlPayRequest({
    required this.username,
    required this.time,
    required this.webhookUrl,
    required this.signature,
  });

  RegisterLnurlPayRequest copyWith({
    String? username,
    int? time,
    String? webhookUrl,
    String? signature,
  }) {
    return RegisterLnurlPayRequest(
      username: username ?? this.username,
      time: time ?? this.time,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      signature: signature ?? this.signature,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'username': username,
      'time': time,
      'webhook_url': webhookUrl,
      'signature': signature,
    };
  }

  @override
  String toString() => 'username=$username, time=$time, webhook_url=$webhookUrl, signature=$signature';
}

class RegisterLnurlPayResponse {
  final String lnurl;
  final String lightningAddress;

  const RegisterLnurlPayResponse({
    required this.lnurl,
    required this.lightningAddress,
  });

  factory RegisterLnurlPayResponse.fromJson(Map<String, dynamic> json) {
    return RegisterLnurlPayResponse(
      lnurl: json['lnurl'] as String,
      lightningAddress: json['lightning_address'] as String? ?? '',
    );
  }

  @override
  String toString() => 'lnurl=$lnurl, lightning_address=$lightningAddress';
}

class UnregisterLnurlPayRequest {
  final int time;
  final String webhookUrl;
  final String signature;

  const UnregisterLnurlPayRequest({
    required this.time,
    required this.webhookUrl,
    required this.signature,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'time': time,
      'webhook_url': webhookUrl,
      'signature': signature,
    };
  }

  @override
  String toString() => 'time=$time, webhook_url=$webhookUrl, signature=$signature';
}
