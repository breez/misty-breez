import 'package:flutter/material.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/currency.dart';
import 'package:misty_breez/routes/nwc/widgets/connection_item/nwc_connection_item_info_row.dart';

class NwcConnectionItemContent extends StatelessWidget {
  final NwcConnectionModel connection;
  final bool isExpiringWithinWeek;

  const NwcConnectionItemContent({required this.connection, required this.isExpiringWithinWeek, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Budget information
          if (connection.periodicBudget != null) ...<Widget>[
            NwcConnectionItemInfoRow(label: 'Budget:', value: _buildBudgetValue()),
          ],

          // Renewal date
          if (connection.periodicBudget?.renewsAt != null) ...<Widget>[
            NwcConnectionItemInfoRow(
              label: 'Renews:',
              value: _formatCompactDate(
                DateTime.fromMillisecondsSinceEpoch(connection.periodicBudget!.renewsAt! * 1000),
              ),
              valueColor: const Color(0xFFD1D5DB),
            ),
          ],

          // Expiration date (only if expiring within a week)
          if (isExpiringWithinWeek) ...<Widget>[
            NwcConnectionItemInfoRow(
              label: 'Expires:',
              value: _formatCompactDate(DateTime.fromMillisecondsSinceEpoch(connection.expiresAt! * 1000)),
              labelColor: const Color(0xFFFB923C),
              valueColor: const Color(0xFFFB923C),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCompactDate(DateTime date) {
    final Duration diff = date.difference(DateTime.now());
    final int hours = diff.inHours;
    final int days = diff.inDays;

    if (days > 0) {
      return '${days}d';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return 'Soon';
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

  String _buildBudgetValue() {
    if (connection.periodicBudget == null) {
      return '';
    }

    final int maxBudgetSat = connection.periodicBudget!.maxBudgetSat.toInt();
    String budgetText = _formatSats(maxBudgetSat);

    // Add renewal interval if available
    if (connection.periodicBudget!.renewsAt != null) {
      final int renewalIntervalMins =
          ((connection.periodicBudget!.renewsAt! - connection.periodicBudget!.updatedAt) / 60).round();
      final String renewalLabel = _getRenewalLabel(renewalIntervalMins);
      if (renewalLabel.isNotEmpty) {
        budgetText += ' $renewalLabel';
      }
    }

    return budgetText;
  }
}
