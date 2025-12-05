import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/routes/dev/widgets/status_item.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/routes/routes.dart';

class NwcConnectionParametersCard extends StatelessWidget {
  final NwcConnectionModel connection;

  const NwcConnectionParametersCard({required this.connection, super.key});

  @override
  Widget build(BuildContext context) {
    // Don't show card if no parameters are set
    if (connection.periodicBudget == null && connection.expiresAt == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          <Widget>[
              if (connection.periodicBudget != null) ...<Widget>[
                StatusItem(label: 'Budget', value: _formatBudgetValue(connection.periodicBudget!)),
              ],
              if (connection.periodicBudget?.renewsAt != null) ...<Widget>[
                StatusItem(
                  label: 'Renewal',
                  value: _formatRenewalTime(
                    DateTime.fromMillisecondsSinceEpoch(connection.periodicBudget!.renewsAt! * 1000),
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

  String _formatRenewalTime(DateTime date) {
    final Duration diff = date.difference(DateTime.now());
    final int days = diff.inDays;
    final int hours = diff.inHours;
    final int minutes = diff.inMinutes;

    if (days > 1) {
      return '$days days';
    } else if (days == 1) {
      return '1 day';
    } else if (hours > 1) {
      return '$hours hours';
    } else if (hours == 1) {
      return '1 hour';
    } else if (minutes > 1) {
      return '$minutes minutes';
    } else if (minutes == 1) {
      return '1 minute';
    } else {
      return 'Renews soon';
    }
  }

  String _formatSats(int amount) {
    return BitcoinCurrency.sat.format(amount, removeTrailingZeros: true);
  }

  String _formatBudgetValue(PeriodicBudget budget) {
    final int maxBudgetSat = budget.maxBudgetSat.toInt();
    final int usedBudgetSat = budget.usedBudgetSat.toInt();
    final int remainingBudgetSat = maxBudgetSat - usedBudgetSat;

    String value = '';
    if (remainingBudgetSat < maxBudgetSat) {
      value = '${_formatSats(remainingBudgetSat)} / ';
    }
    value += _formatSats(maxBudgetSat);

    return value;
  }

  String _formatExpiryTime(int? expiresAt) {
    if (expiresAt == null) {
      return 'Never';
    }
    return BreezDateUtils.formatYearMonthDay(DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000));
  }
}
