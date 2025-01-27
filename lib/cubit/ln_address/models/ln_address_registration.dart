class LnAddressRegistrationRequest {
  final int timestamp;
  final String webhookUrl;
  final String signature;
  final String? username;

  const LnAddressRegistrationRequest({
    required this.timestamp,
    required this.webhookUrl,
    required this.signature,
    required this.username,
  });

  LnAddressRegistrationRequest copyWith({
    int? timestamp,
    String? webhookUrl,
    String? signature,
    String? username,
  }) {
    return LnAddressRegistrationRequest(
      timestamp: timestamp ?? this.timestamp,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      signature: signature ?? this.signature,
      username: username ?? this.username,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'time': timestamp,
      'webhook_url': webhookUrl,
      'signature': signature,
      'username': username,
    };
  }
}

class LnAddressRegistrationResponse {
  final String lnurl;
  final String lnAddress;

  const LnAddressRegistrationResponse({
    required this.lnurl,
    required this.lnAddress,
  });

  factory LnAddressRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return LnAddressRegistrationResponse(
      lnurl: json['lnurl'] as String,
      lnAddress: json['lightning_address'] as String? ?? '',
    );
  }

  @override
  String toString() => 'lnurl=$lnurl, lnAddress=$lnAddress';
}

class InvalidateWebhookRequest {
  final int timestamp;
  final String webhookUrl;
  final String signature;

  const InvalidateWebhookRequest({
    required this.timestamp,
    required this.webhookUrl,
    required this.signature,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'time': timestamp,
      'webhook_url': webhookUrl,
      'signature': signature,
    };
  }
}
