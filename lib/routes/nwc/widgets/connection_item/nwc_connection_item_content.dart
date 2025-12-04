import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/routes/dev/widgets/status_item.dart';

class NwcConnectionItemContent extends StatelessWidget {
  final NwcConnectionModel connection;
  final bool isExpiringWithinWeek;

  const NwcConnectionItemContent({required this.connection, required this.isExpiringWithinWeek, super.key});

  @override
  Widget build(BuildContext context) {
    if (connection.periodicBudget == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            <Widget>[
                // Budget information
                if (connection.periodicBudget != null) ...<Widget>[
                  StatusItem(label: 'Budget', value: _formatBudgetValue(connection.periodicBudget!)),
                ],

                // Renewal date
                if (connection.periodicBudget?.renewsAt != null) ...<Widget>[
                  StatusItem(
                    label: 'Renewal',
                    value: _formatRenewalTime(
                      DateTime.fromMillisecondsSinceEpoch(connection.periodicBudget!.renewsAt! * 1000),
                    ),
                  ),
                ],
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
      ),
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

  String _getRenewalLabel(int renewalTimeMins) {
    switch (renewalTimeMins) {
      case 1440:
        return 'per day';
      case 10080:
        return 'per week';
      case 43200:
        return 'per month';
      case 525600:
        return 'per year';
      default:
        return '';
    }
  }

  String _formatSats(int amount) {
    return BitcoinCurrency.sat.format(amount, removeTrailingZeros: true);
  }

  String _formatBudgetValue(PeriodicBudget budget) {
    final int maxBudgetSat = budget.maxBudgetSat.toInt();
    final int usedBudgetSat = budget.usedBudgetSat.toInt();
    final int remainingBudgetSat = maxBudgetSat - usedBudgetSat;

    // Get renewal label
    String renewalLabel = '';
    if (budget.renewsAt != null) {
      final int renewalIntervalMins = ((budget.renewsAt! - budget.updatedAt) / 60).round();
      renewalLabel = _getRenewalLabel(renewalIntervalMins);
    }

    // Build the value string
    String value = '';
    if (remainingBudgetSat < maxBudgetSat) {
      value = '${_formatSats(remainingBudgetSat)} / ';
    }
    value += _formatSats(maxBudgetSat);
    if (renewalLabel.isNotEmpty) {
      value += ' $renewalLabel';
    }

    return value;
  }
}
