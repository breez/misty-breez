import 'dart:convert';

import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/utils/utils.dart';

// TODO(erdemyerebasmaz): Ensure that any changes to [PaymentDetails] are reflected here on each extension.
extension PaymentDetailsMapExtension on PaymentDetails {
  T map<T>({
    required T Function() orElse,
    T Function(PaymentDetails_Bitcoin details)? bitcoin,
    T Function(PaymentDetails_Lightning details)? lightning,
    T Function(PaymentDetails_Liquid details)? liquid,
  }) {
    if (this is PaymentDetails_Bitcoin) {
      return bitcoin != null ? bitcoin(this as PaymentDetails_Bitcoin) : orElse();
    } else if (this is PaymentDetails_Lightning) {
      return lightning != null ? lightning(this as PaymentDetails_Lightning) : orElse();
    } else if (this is PaymentDetails_Liquid) {
      return liquid != null ? liquid(this as PaymentDetails_Liquid) : orElse();
    } else {
      return orElse();
    }
  }
}

extension PaymentDetailsToJson on PaymentDetails {
  Map<String, dynamic>? toJson() {
    return map(
      lightning: (PaymentDetails_Lightning details) => <String, dynamic>{
        'type': 'lightning',
        'swapId': details.swapId,
        'description': details.description,
        'liquidExpirationBlockheight': details.liquidExpirationBlockheight,
        'preimage': details.preimage,
        'invoice': details.invoice,
        'bolt12Offer': details.bolt12Offer,
        'paymentHash': details.paymentHash,
        'destinationPubkey': details.destinationPubkey,
        'lnurlInfo': details.lnurlInfo?.toJson(),
        'bip353Address': details.bip353Address,
        'claimTxId': details.claimTxId,
        'refundTxId': details.refundTxId,
        'refundTxAmountSat': details.refundTxAmountSat?.toString(),
      },
      liquid: (PaymentDetails_Liquid details) => <String, dynamic>{
        'type': 'liquid',
        'destination': details.destination,
        'description': details.description,
        'assetId': details.assetId,
        'assetInfo': details.assetInfo?.toJson(),
        'lnurlInfo': details.lnurlInfo?.toJson(),
        'bip353Address': details.bip353Address,
      },
      bitcoin: (PaymentDetails_Bitcoin details) => <String, dynamic>{
        'type': 'bitcoin',
        'swapId': details.swapId,
        'bitcoinAddress': details.bitcoinAddress,
        'description': details.description,
        'autoAcceptedFees': details.autoAcceptedFees,
        'liquidExpirationBlockheight': details.liquidExpirationBlockheight,
        'bitcoinExpirationBlockheight': details.bitcoinExpirationBlockheight,
        'claimTxId': details.claimTxId,
        'refundTxId': details.refundTxId,
        'refundTxAmountSat': details.refundTxAmountSat?.toString(),
      },
      orElse: () => null,
    );
  }
}

extension PaymentDetailsFromJson on PaymentDetails {
  static PaymentDetails fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'lightning':
        return PaymentDetails.lightning(
          swapId: json['swapId'] as String,
          description: json['description'] as String,
          liquidExpirationBlockheight: json['liquidExpirationBlockheight'] as int,
          preimage: json['preimage'] as String?,
          invoice: json['invoice'] as String?,
          bolt12Offer: json['bolt12Offer'] as String?,
          paymentHash: json['paymentHash'] as String?,
          destinationPubkey: json['destinationPubkey'] as String?,
          lnurlInfo: json['lnurlInfo'] != null ? LnUrlInfoFromJson.fromJson(json['lnurlInfo']) : null,
          bip353Address: json['bip353Address'] as String?,
          claimTxId: json['claimTxId'] as String?,
          refundTxId: json['refundTxId'] as String?,
          refundTxAmountSat: json['refundTxAmountSat'] != null
              ? BigInt.parse(json['refundTxAmountSat'] as String)
              : null,
        );

      case 'liquid':
        return PaymentDetails.liquid(
          destination: json['destination'] as String,
          description: json['description'] as String,
          assetId: json['assetId'] as String,
          assetInfo: json['assetInfo'] != null ? AssetInfoFromJson.fromJson(json['assetInfo']) : null,
          lnurlInfo: json['lnurlInfo'] != null ? LnUrlInfoFromJson.fromJson(json['lnurlInfo']) : null,
          bip353Address: json['bip353Address'] as String?,
        );

      case 'bitcoin':
        return PaymentDetails.bitcoin(
          swapId: json['swapId'] as String,
          bitcoinAddress: json['bitcoinAddress'] as String,
          description: json['description'] as String,
          autoAcceptedFees: json['autoAcceptedFees'] as bool,
          liquidExpirationBlockheight: json['liquidExpirationBlockheight'] as int?,
          bitcoinExpirationBlockheight: json['bitcoinExpirationBlockheight'] as int?,
          claimTxId: json['claimTxId'] as String?,
          refundTxId: json['refundTxId'] as String?,
          refundTxAmountSat: json['refundTxAmountSat'] != null
              ? BigInt.parse(json['refundTxAmountSat'] as String)
              : null,
        );

      default:
        throw Exception('Unknown PaymentDetails type: ${json['type']}');
    }
  }
}

extension PaymentDetailsExtension on PaymentDetails {
  bool equals(PaymentDetails other) {
    return identical(this, other) ||
        other.runtimeType == runtimeType &&
            other.map(
              lightning: (PaymentDetails_Lightning o) {
                final PaymentDetails_Lightning current = this as PaymentDetails_Lightning;
                return o.swapId == current.swapId &&
                    o.description == current.description &&
                    o.liquidExpirationBlockheight == current.liquidExpirationBlockheight &&
                    o.preimage == current.preimage &&
                    o.invoice == current.invoice &&
                    o.bolt12Offer == current.bolt12Offer &&
                    o.paymentHash == current.paymentHash &&
                    o.destinationPubkey == current.destinationPubkey &&
                    (o.lnurlInfo?.toJson() == current.lnurlInfo?.toJson()) &&
                    o.bip353Address == current.bip353Address &&
                    o.claimTxId == current.claimTxId &&
                    o.refundTxId == current.refundTxId &&
                    o.refundTxAmountSat == current.refundTxAmountSat;
              },
              liquid: (PaymentDetails_Liquid o) {
                final PaymentDetails_Liquid current = this as PaymentDetails_Liquid;
                return o.destination == current.destination &&
                    o.description == current.description &&
                    o.assetId == current.assetId &&
                    (o.assetInfo?.toJson() == current.assetInfo?.toJson()) &&
                    (o.lnurlInfo?.toJson() == current.lnurlInfo?.toJson()) &&
                    o.bip353Address == current.bip353Address;
              },
              bitcoin: (PaymentDetails_Bitcoin o) {
                final PaymentDetails_Bitcoin current = this as PaymentDetails_Bitcoin;
                return o.swapId == current.swapId &&
                    o.bitcoinAddress == current.bitcoinAddress &&
                    o.description == current.description &&
                    o.autoAcceptedFees == current.autoAcceptedFees &&
                    o.liquidExpirationBlockheight == current.liquidExpirationBlockheight &&
                    o.bitcoinExpirationBlockheight == current.bitcoinExpirationBlockheight &&
                    o.claimTxId == current.claimTxId &&
                    o.refundTxId == current.refundTxId &&
                    o.refundTxAmountSat == current.refundTxAmountSat;
              },
              orElse: () => false,
            );
  }
}

extension PaymentDetailsHashCode on PaymentDetails {
  int calculateHashCode() {
    return map(
      lightning: (PaymentDetails_Lightning o) => Object.hash(
        o.swapId,
        o.description,
        o.liquidExpirationBlockheight,
        o.preimage,
        o.invoice,
        o.bolt12Offer,
        o.paymentHash,
        o.destinationPubkey,
        o.lnurlInfo?.toJson(),
        o.bip353Address,
        o.claimTxId,
        o.refundTxId,
        o.refundTxAmountSat,
      ),
      liquid: (PaymentDetails_Liquid o) =>
          Object.hash(o.destination, o.description, o.assetId, o.assetInfo?.toJson()),
      bitcoin: (PaymentDetails_Bitcoin o) => Object.hash(
        o.swapId,
        o.bitcoinAddress,
        o.description,
        o.autoAcceptedFees,
        o.liquidExpirationBlockheight,
        o.bitcoinExpirationBlockheight,
        o.claimTxId,
        o.refundTxId,
        o.refundTxAmountSat,
      ),
      orElse: () => 0,
    );
  }
}

extension PaymentDetailsExpiryDate on PaymentDetails {
  DateTime? getExpiryDate({required BlockchainInfo? blockchainInfo}) {
    if (blockchainInfo == null) {
      return null;
    }

    final int? expiryBlockheight = map(
      bitcoin: (PaymentDetails_Bitcoin details) => details.bitcoinExpirationBlockheight,
      lightning: (PaymentDetails_Lightning details) => details.liquidExpirationBlockheight,
      orElse: () => null,
    );

    if (expiryBlockheight == null) {
      return null;
    }

    final int? currentTip = map(
      bitcoin: (_) => blockchainInfo.bitcoinTip,
      lightning: (_) => blockchainInfo.liquidTip,
      orElse: () => null,
    );

    if (currentTip == null) {
      return null;
    }

    return map(
      bitcoin: (_) =>
          BreezDateUtils.bitcoinBlockDiffToDate(blockHeight: currentTip, expiryBlock: expiryBlockheight),
      lightning: (_) =>
          BreezDateUtils.liquidBlockDiffToDate(blockHeight: currentTip, expiryBlock: expiryBlockheight),
      orElse: () => null,
    );
  }
}

extension PaymentDetailsFormatter on PaymentDetails {
  String toFormattedString() {
    if (this is PaymentDetails_Lightning) {
      final PaymentDetails_Lightning details = this as PaymentDetails_Lightning;
      return 'PaymentDetails_Lightning('
          'swapId: ${details.swapId}, '
          'description: ${details.description}, '
          'liquidExpirationBlockheight: ${details.liquidExpirationBlockheight}, '
          'preimage: ${details.preimage ?? "N/A"}, '
          'invoice: ${details.invoice ?? "N/A"}, '
          'bolt12Offer: ${details.bolt12Offer ?? "N/A"}, '
          'paymentHash: ${details.paymentHash ?? "N/A"}, '
          'destinationPubkey: ${details.destinationPubkey ?? "N/A"}, '
          'lnurlInfo: ${details.lnurlInfo?.toFormattedString() ?? "N/A"}, '
          'bip353Address: ${details.bip353Address ?? "N/A"}, '
          'claimTxId: ${details.claimTxId ?? "N/A"}, '
          'refundTxId: ${details.refundTxId ?? "N/A"}, '
          'refundTxAmountSat: ${details.refundTxAmountSat ?? "N/A"}'
          ')';
    } else if (this is PaymentDetails_Liquid) {
      final PaymentDetails_Liquid details = this as PaymentDetails_Liquid;
      return 'PaymentDetails_Liquid('
          'destination: ${details.destination}, '
          'description: ${details.description}, '
          'assetId: ${details.assetId}, '
          'assetInfo: ${details.assetInfo ?? "N/A"}'
          'lnurlInfo: ${details.lnurlInfo?.toFormattedString() ?? "N/A"}, '
          'bip353Address: ${details.bip353Address ?? "N/A"}, '
          ')';
    } else if (this is PaymentDetails_Bitcoin) {
      final PaymentDetails_Bitcoin details = this as PaymentDetails_Bitcoin;
      return 'PaymentDetails_Bitcoin('
          'swapId: ${details.swapId}, '
          'bitcoinAddress: ${details.bitcoinAddress}, '
          'description: ${details.description}, '
          'autoAcceptedFees: ${details.autoAcceptedFees}, '
          'liquidExpirationBlockheight: ${details.liquidExpirationBlockheight ?? "N/A"}, '
          'bitcoinExpirationBlockheight: ${details.bitcoinExpirationBlockheight ?? "N/A"}, '
          'claimTxId: ${details.claimTxId ?? "N/A"}, '
          'refundTxId: ${details.refundTxId ?? "N/A"}, '
          'refundTxAmountSat: ${details.refundTxAmountSat ?? "N/A"}'
          ')';
    } else {
      return 'Unknown PaymentDetails';
    }
  }
}

extension LnUrlInfoFormatter on LnUrlInfo {
  String toFormattedString() {
    return 'LnUrlInfo('
        'lnAddress: $lnAddress, '
        'lnurlPayDomain: $lnurlPayDomain, '
        'lnurlPayComment: $lnurlPayComment, '
        'lnurlPayMetadata: ${_parseMetadata()}, '
        'lnurlPaySuccessAction: ${_safeJsonEncode(lnurlPaySuccessAction?.toJson())}, '
        'lnurlPayUnprocessedSuccessAction: ${_safeJsonEncode(lnurlPayUnprocessedSuccessAction?.toJson())}, '
        'lnurlWithdrawEndpoint: $lnurlWithdrawEndpoint, '
        ')';
  }

  String _parseMetadata() {
    if (lnurlPayMetadata == null || lnurlPayMetadata!.isEmpty) {
      return 'null';
    }

    try {
      final List<dynamic> parsed = jsonDecode(lnurlPayMetadata!);
      final Map<String, String> metadata = <String, String>{};

      for (int i = 0; i < parsed.length; i++) {
        final String item = parsed[i];
        if (item is List && item.length >= 2) {
          metadata[item[0].toString()] = item[1].toString();
        }
      }

      return metadata.toString();
    } catch (e) {
      return 'parse_error: ${lnurlPayMetadata!.substring(0, 50)}...';
    }
  }

  String _safeJsonEncode(Map<String, dynamic>? data) {
    if (data == null) {
      return 'null';
    }

    try {
      return jsonEncode(data);
    } catch (e) {
      return 'encoding_error: ${e.toString()}';
    }
  }
}

extension LnUrlInfoToJson on LnUrlInfo {
  Map<String, dynamic> toJson() => <String, dynamic>{
    'lnAddress': lnAddress,
    'lnurlPayComment': lnurlPayComment,
    'lnurlPayDomain': lnurlPayDomain,
    'lnurlPayMetadata': lnurlPayMetadata,
    'lnurlPaySuccessAction': lnurlPaySuccessAction?.toJson(),
    'lnurlPayUnprocessedSuccessAction': lnurlPayUnprocessedSuccessAction?.toJson(),
    'lnurlWithdrawEndpoint': lnurlWithdrawEndpoint,
  };
}

extension LnUrlInfoFromJson on LnUrlInfo {
  static LnUrlInfo fromJson(Map<String, dynamic> json) {
    return LnUrlInfo(
      lnAddress: json['lnAddress'] as String?,
      lnurlPayComment: json['lnurlPayComment'] as String?,
      lnurlPayDomain: json['lnurlPayDomain'] as String?,
      lnurlPayMetadata: json['lnurlPayMetadata'] as String?,
      lnurlPaySuccessAction: json['lnurlPaySuccessAction'] != null
          ? SuccessActionProcessedFromJson.fromJson(json['lnurlPaySuccessAction'])
          : null,
      lnurlPayUnprocessedSuccessAction: json['lnurlPayUnprocessedSuccessAction'] != null
          ? SuccessActionFromJson.fromJson(json['lnurlPayUnprocessedSuccessAction'])
          : null,
      lnurlWithdrawEndpoint: json['lnurlWithdrawEndpoint'] as String?,
    );
  }
}

extension SuccessActionProcessedToJson on SuccessActionProcessed {
  Map<String, dynamic> toJson() {
    if (this is SuccessActionProcessed_Aes) {
      return <String, dynamic>{'type': 'aes', 'result': (this as SuccessActionProcessed_Aes).result.toJson()};
    } else if (this is SuccessActionProcessed_Message) {
      return <String, dynamic>{
        'type': 'message',
        'data': (this as SuccessActionProcessed_Message).data.toJson(),
      };
    } else if (this is SuccessActionProcessed_Url) {
      return <String, dynamic>{'type': 'url', 'data': (this as SuccessActionProcessed_Url).data.toJson()};
    } else {
      throw Exception('Unknown SuccessActionProcessed type');
    }
  }
}

extension SuccessActionProcessedFromJson on SuccessActionProcessed {
  static SuccessActionProcessed fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'aes':
        return SuccessActionProcessed.aes(
          result: AesSuccessActionDataResultFromJson.fromJson(json['result']),
        );
      case 'message':
        return SuccessActionProcessed.message(data: MessageSuccessActionDataFromJson.fromJson(json['data']));
      case 'url':
        return SuccessActionProcessed.url(data: UrlSuccessActionDataFromJson.fromJson(json['data']));
      default:
        throw Exception('Unknown SuccessActionProcessed type: ${json['type']}');
    }
  }
}

extension AesSuccessActionDataResultToJson on AesSuccessActionDataResult {
  Map<String, dynamic> toJson() {
    if (this is AesSuccessActionDataResult_Decrypted) {
      return <String, dynamic>{
        'type': 'decrypted',
        'data': (this as AesSuccessActionDataResult_Decrypted).data.toJson(),
      };
    } else if (this is AesSuccessActionDataResult_ErrorStatus) {
      return <String, dynamic>{
        'type': 'errorStatus',
        'reason': (this as AesSuccessActionDataResult_ErrorStatus).reason,
      };
    } else {
      throw Exception('Unknown AesSuccessActionDataResult type');
    }
  }
}

extension AesSuccessActionDataResultFromJson on AesSuccessActionDataResult {
  static AesSuccessActionDataResult fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'decrypted':
        return AesSuccessActionDataResult.decrypted(
          data: AesSuccessActionDataDecryptedFromJson.fromJson(json['data']),
        );
      case 'errorStatus':
        return AesSuccessActionDataResult.errorStatus(reason: json['reason'] as String);
      default:
        throw Exception('Unknown AesSuccessActionDataResult type: ${json['type']}');
    }
  }
}

extension AesSuccessActionDataDecryptedToJson on AesSuccessActionDataDecrypted {
  Map<String, String> toJson() => <String, String>{'description': description, 'plaintext': plaintext};
}

extension AesSuccessActionDataDecryptedFromJson on AesSuccessActionDataDecrypted {
  static AesSuccessActionDataDecrypted fromJson(Map<String, dynamic> json) {
    return AesSuccessActionDataDecrypted(
      description: json['description'] as String,
      plaintext: json['plaintext'] as String,
    );
  }
}

extension MessageSuccessActionDataToJson on MessageSuccessActionData {
  Map<String, dynamic> toJson() => <String, dynamic>{'message': message};
}

extension MessageSuccessActionDataFromJson on MessageSuccessActionData {
  static MessageSuccessActionData fromJson(Map<String, dynamic> json) {
    return MessageSuccessActionData(message: json['message'] as String);
  }
}

extension UrlSuccessActionDataToJson on UrlSuccessActionData {
  Map<String, dynamic> toJson() => <String, dynamic>{
    'description': description,
    'url': url,
    'matchesCallbackDomain': matchesCallbackDomain,
  };
}

extension UrlSuccessActionDataFromJson on UrlSuccessActionData {
  static UrlSuccessActionData fromJson(Map<String, dynamic> json) {
    return UrlSuccessActionData(
      description: json['description'] as String,
      url: json['url'] as String,
      matchesCallbackDomain: json['matchesCallbackDomain'] as bool,
    );
  }
}

extension SuccessActionToJson on SuccessAction {
  Map<String, dynamic> toJson() {
    if (this is SuccessAction_Aes) {
      return <String, dynamic>{'type': 'aes', 'data': (this as SuccessAction_Aes).data.toJson()};
    } else if (this is SuccessAction_Message) {
      return <String, dynamic>{'type': 'message', 'data': (this as SuccessAction_Message).data.toJson()};
    } else if (this is SuccessAction_Url) {
      return <String, dynamic>{'type': 'url', 'data': (this as SuccessAction_Url).data.toJson()};
    } else {
      throw Exception('Unknown SuccessAction type');
    }
  }
}

extension SuccessActionFromJson on SuccessAction {
  static SuccessAction fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'aes':
        return SuccessAction.aes(data: AesSuccessActionDataFromJson.fromJson(json['data']));
      case 'message':
        return SuccessAction.message(data: MessageSuccessActionDataFromJson.fromJson(json['data']));
      case 'url':
        return SuccessAction.url(data: UrlSuccessActionDataFromJson.fromJson(json['data']));
      default:
        throw Exception('Unknown SuccessAction type: ${json['type']}');
    }
  }
}

extension AesSuccessActionDataToJson on AesSuccessActionData {
  Map<String, dynamic> toJson() => <String, String>{
    'description': description,
    'ciphertext': ciphertext,
    'iv': iv,
  };
}

extension AesSuccessActionDataFromJson on AesSuccessActionData {
  static AesSuccessActionData fromJson(Map<String, dynamic> json) {
    return AesSuccessActionData(
      description: json['description'] as String,
      ciphertext: json['ciphertext'] as String,
      iv: json['iv'] as String,
    );
  }
}

extension PaymentDetailsBolt12Offer on PaymentDetails {
  bool get hasBolt12Offer {
    return map(
      lightning: (PaymentDetails_Lightning details) =>
          details.bolt12Offer != null && details.bolt12Offer!.isNotEmpty,
      orElse: () => false,
    );
  }
}
