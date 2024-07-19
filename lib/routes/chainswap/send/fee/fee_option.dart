import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

enum ProcessingSpeed {
  economy(Duration(minutes: 60)),
  regular(Duration(minutes: 30)),
  priority(Duration(minutes: 10));

  const ProcessingSpeed(this.waitingTime);
  final Duration waitingTime;
}

extension PreparePayOnchainResponseAffordable on PreparePayOnchainResponse {
  bool isAffordable({required int balance}) {
    return balance >= (receiverAmountSat + totalFeesSat).toInt();
  }
}

abstract class FeeOption {
  final BigInt txFeeSat;
  final ProcessingSpeed processingSpeed;
  final BigInt satPerVbyte;

  FeeOption({
    required this.txFeeSat,
    required this.processingSpeed,
    required this.satPerVbyte,
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

  bool isAffordable({int? balanceSat, int? walletBalanceSat, required int amountSat});
}

class SendChainSwapFeeOption extends FeeOption {
  final PreparePayOnchainResponse pairInfo;

  SendChainSwapFeeOption({
    required this.pairInfo,
    required super.txFeeSat,
    required super.processingSpeed,
    required super.satPerVbyte,
  });

  @override
  bool isAffordable({int? balanceSat, int? walletBalanceSat, required int amountSat}) {
    assert(balanceSat != null);

    return pairInfo.isAffordable(balance: balanceSat!);
  }
}
