import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/chainswap/send/fee/fee_breakdown/widgets/fee_breakdown_widgets/recipient_amount.dart';
import 'package:l_breez/routes/chainswap/send/fee/fee_breakdown/widgets/fee_breakdown_widgets/sender_amount.dart';
import 'package:l_breez/routes/chainswap/send/fee/fee_breakdown/widgets/fee_breakdown_widgets/transaction_fee.dart';

class FeeBreakdown extends StatelessWidget {
  final PreparePayOnchainResponse feeOption;

  const FeeBreakdown({required this.feeOption, super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5.0)),
        border: Border.all(
          color: themeData.colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SenderAmount(amountSat: (feeOption.receiverAmountSat + feeOption.feesSat).toInt()),
          TransactionFee(txFeeSat: feeOption.feesSat.toInt()),
          RecipientAmount(amountSat: feeOption.receiverAmountSat.toInt())
        ],
      ),
    );
  }
}
