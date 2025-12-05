import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/routes/dev/widgets/status_item.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/utils/utils.dart';

class NwcConnectionParametersCard extends StatelessWidget {
  final NwcConnectionModel connection;

  const NwcConnectionParametersCard({required this.connection, super.key});

  @override
  Widget build(BuildContext context) {
    // Don't show card if no parameters are set
    final PeriodicBudget? budget = connection.periodicBudget;
    if (budget == null) {
      return const SizedBox.shrink();
    }
    if (connection.expiresAt == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          <Widget>[
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
                StatusItem(
                  label: 'Renewal Interval',
                  value: '${((budget.renewsAt! - budget.updatedAt) / 60 / 1440).round()} days',
                ),
                StatusItem(
                  label: 'Renewal Date',
                  value: BreezDateUtils.formatYearMonthDay(
                    DateTime.fromMillisecondsSinceEpoch(budget.renewsAt! * 1000),
                  ),
                ),
              ],
              StatusItem(label: 'Expiration', value: _formatExpiryTime(connection.expiresAt)),
            ].expand((Widget widget) sync* {
              yield widget;
              yield const Divider(
                height: 32.0,
                color: Color.fromRGBO(40, 59, 74, 0.5),
                indent: 0.0,
                endIndent: 0.0,
              );
            }).toList()
            ..removeLast(),
    );
  }

  String _formatExpiryTime(int? expiresAt) {
    if (expiresAt == null) {
      return 'Never';
    }
    return BreezDateUtils.formatYearMonthDay(DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000));
  }
}
