import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';

class NwcConnectionItemContent extends StatelessWidget {
  final NwcConnectionModel connection;
  final bool isExpiringWithinWeek;

  const NwcConnectionItemContent({required this.connection, required this.isExpiringWithinWeek, super.key});

  @override
  Widget build(BuildContext context) {
    if (connection.periodicBudget == null) {
      return const SizedBox.shrink();
    }

    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Budget information
          if (connection.periodicBudget != null) ...<Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Budget',
                  style: themeData.primaryTextTheme.headlineMedium?.copyWith(
                    fontSize: 14.3,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 4),
                _buildBudgetValue(themeData),
              ],
            ),
          ],

          // Renewal date
          if (connection.periodicBudget?.renewsAt != null) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _buildRenewalText(
                themeData,
                DateTime.fromMillisecondsSinceEpoch(connection.periodicBudget!.renewsAt! * 1000),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRenewalText(ThemeData themeData, DateTime date) {
    final Duration diff = date.difference(DateTime.now());
    final int days = diff.inDays;
    final int hours = diff.inHours;
    final int minutes = diff.inMinutes;

    String number;
    String unit;

    if (days > 1) {
      number = '$days';
      unit = ' days';
    } else if (days == 1) {
      number = '1';
      unit = ' day';
    } else if (hours > 1) {
      number = '$hours';
      unit = ' hours';
    } else if (hours == 1) {
      number = '1';
      unit = ' hour';
    } else if (minutes > 1) {
      number = '$minutes';
      unit = ' minutes';
    } else if (minutes == 1) {
      number = '1';
      unit = ' minute';
    } else {
      return Text(
        'Renews soon',
        style: themeData.primaryTextTheme.headlineMedium?.copyWith(fontSize: 10.0, color: Colors.white70),
      );
    }

    return RichText(
      text: TextSpan(
        style: themeData.primaryTextTheme.headlineMedium?.copyWith(fontSize: 10.0, color: Colors.white54),
        children: <TextSpan>[
          const TextSpan(text: 'Renews in '),
          TextSpan(
            text: number,
            style: const TextStyle(fontSize: 12.0, color: Colors.white),
          ),
          TextSpan(text: unit),
        ],
      ),
    );
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

  Widget _buildBudgetValue(ThemeData themeData) {
    if (connection.periodicBudget == null) {
      return const SizedBox.shrink();
    }

    final PeriodicBudget budget = connection.periodicBudget!;
    final int maxBudgetSat = budget.maxBudgetSat.toInt();
    final int usedBudgetSat = budget.usedBudgetSat.toInt();
    final int remainingBudgetSat = maxBudgetSat - usedBudgetSat;

    // Get renewal label
    String renewalLabel = '';
    if (budget.renewsAt != null) {
      final int renewalIntervalMins = ((budget.renewsAt! - budget.updatedAt) / 60).round();
      renewalLabel = _getRenewalLabel(renewalIntervalMins);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Budget amount with used/max
        RichText(
          textAlign: TextAlign.right,
          text: TextSpan(
            style: themeData.primaryTextTheme.displaySmall?.copyWith(fontSize: 16.0, color: Colors.white),
            children: <TextSpan>[
              // Show remaining budget if different from max (i.e., some has been used)
              if (remainingBudgetSat < maxBudgetSat) ...<TextSpan>[
                TextSpan(text: '${_formatSats(remainingBudgetSat)} / '),
              ],
              // Max budget
              TextSpan(text: _formatSats(maxBudgetSat)),
              // Renewal label in lighter color
              if (renewalLabel.isNotEmpty)
                TextSpan(
                  text: ' $renewalLabel',
                  style: const TextStyle(color: Colors.white38),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
