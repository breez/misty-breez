import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/models/sdk_formatted_string_extensions.dart';

enum ProcessingSpeed {
  economy(Duration(minutes: 60)),
  regular(Duration(minutes: 30)),
  priority(Duration(minutes: 10));

  const ProcessingSpeed(this.waitingTime);
  final Duration waitingTime;
}

abstract class FeeOption {
  final ProcessingSpeed processingSpeed;
  final BigInt feeRateSatPerVbyte;

  FeeOption({
    required this.processingSpeed,
    required this.feeRateSatPerVbyte,
  });

  String getDisplayName(BreezTranslations texts) {
    switch (processingSpeed) {
      case ProcessingSpeed.economy:
        return texts.fee_chooser_option_economy;
      case ProcessingSpeed.regular:
        return texts.fee_chooser_option_regular;
      case ProcessingSpeed.priority:
        return texts.fee_chooser_option_priority;
    }
  }

  bool isAffordable({required int amountSat, int? balanceSat, int? walletBalanceSat});
}

class SendChainSwapFeeOption extends FeeOption {
  final PreparePayOnchainResponse preparePayOnchainResponse;

  SendChainSwapFeeOption({
    required this.preparePayOnchainResponse,
    required super.processingSpeed,
    required super.feeRateSatPerVbyte,
  });

  @override
  bool isAffordable({required int amountSat, int? balanceSat, int? walletBalanceSat}) {
    assert(balanceSat != null, 'Balance amount must be provided.');

    return preparePayOnchainResponse.isAffordable(balance: balanceSat!);
  }

  @override
  String toString() {
    return 'SendChainSwapFeeOption('
        'processingSpeed: $processingSpeed, '
        'feeRateSatPerVbyte: $feeRateSatPerVbyte, '
        'prepareRefundResponse: ${preparePayOnchainResponse.toFormattedString()}'
        ')';
  }
}

extension PreparePayOnchainResponseAffordable on PreparePayOnchainResponse {
  bool isAffordable({required int balance}) {
    return balance >= (receiverAmountSat + totalFeesSat).toInt();
  }
}

class RefundFeeOption extends FeeOption {
  final PrepareRefundResponse prepareRefundResponse;

  RefundFeeOption({
    required this.prepareRefundResponse,
    required super.processingSpeed,
    required super.feeRateSatPerVbyte,
  });

  @override
  bool isAffordable({required int amountSat, int? balanceSat, int? walletBalanceSat}) {
    assert(balanceSat != null, 'Balance amount must be provided.');

    return prepareRefundResponse.isAffordable(balance: balanceSat!);
  }

  @override
  String toString() {
    return 'RefundFeeOption('
        'processingSpeed: $processingSpeed, '
        'feeRateSatPerVbyte: $feeRateSatPerVbyte, '
        'prepareRefundResponse: ${prepareRefundResponse.toFormattedString}'
        ')';
  }
}

extension PrepareRefundResponseAffordable on PrepareRefundResponse {
  bool isAffordable({required int balance}) {
    return balance >= (txFeeSat).toInt();
  }
}
