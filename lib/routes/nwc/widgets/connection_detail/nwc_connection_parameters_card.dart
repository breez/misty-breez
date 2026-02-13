import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/routes/dev/widgets/status_item.dart';
import 'package:misty_breez/utils/utils.dart';

class NwcConnectionParametersCard extends StatelessWidget {
  final NwcConnectionModel connection;
  final bool showExpiration;
  final EdgeInsetsGeometry? padding;

  const NwcConnectionParametersCard({
    required this.connection,
    this.showExpiration = false,
    this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final PeriodicBudget? budget = connection.periodicBudget;
    if (budget == null) {
      return const SizedBox.shrink();
    }

    final List<Widget> items = <Widget>[
      StatusItem(
        label: 'Budget',
        value: BitcoinCurrency.sat.format(budget.maxBudgetSat.toInt(), removeTrailingZeros: true),
      ),
      if (budget.usedBudgetSat > BigInt.zero)
        StatusItem(
          label: 'Spent',
          value: BitcoinCurrency.sat.format(budget.usedBudgetSat.toInt(), removeTrailingZeros: true),
        ),
      if (budget.renewsAt != null) ...<Widget>[
        StatusItem(label: 'Renewal Interval', value: '${budget.renewalIntervalDays} days'),
        StatusItem(
          label: 'Renewal Date',
          value: BreezDateUtils.formatYearMonthDay(
            DateTime.fromMillisecondsSinceEpoch(budget.renewsAt! * 1000),
          ),
        ),
      ],
      if (showExpiration) StatusItem(label: 'Expiration', value: _formatExpiryTime(connection.expiresAt)),
    ];

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.expand((Widget widget) sync* {
        yield widget;
        yield const Divider(
          height: 32.0,
          color: Color.fromRGBO(40, 59, 74, 0.5),
          indent: 0.0,
          endIndent: 0.0,
        );
      }).toList()..removeLast(),
    );

    if (padding != null) {
      return Padding(padding: padding!, child: content);
    }
    return content;
  }

  String _formatExpiryTime(int? expiresAt) {
    if (expiresAt == null) {
      return 'Never';
    }
    return BreezDateUtils.formatYearMonthDay(DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000));
  }
}
