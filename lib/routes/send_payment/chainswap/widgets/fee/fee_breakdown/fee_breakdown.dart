import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/routes.dart';

class FeeBreakdown extends StatelessWidget {
  final PreparePayOnchainResponse feeOption;

  const FeeBreakdown({required this.feeOption, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5.0)),
        border: Border.all(
          color: themeData.colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SenderAmount(amountSat: (feeOption.receiverAmountSat + feeOption.totalFeesSat).toInt()),
          BoltzServiceFee(
            boltzServiceFee: (feeOption.totalFeesSat - feeOption.claimFeesSat).toInt(),
          ),
          TransactionFee(txFeeSat: feeOption.claimFeesSat.toInt()),
          RecipientAmount(amountSat: feeOption.receiverAmountSat.toInt()),
        ],
      ),
    );
  }
}
