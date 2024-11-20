import 'package:flutter/widgets.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/routes/routes.dart';

class RefundItem extends StatelessWidget {
  final RefundableSwap refundItem;

  const RefundItem(this.refundItem, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        RefundItemAmount(refundItem.amountSat.toInt()),
        RefundItemAction(refundItem),
      ],
    );
  }
}
