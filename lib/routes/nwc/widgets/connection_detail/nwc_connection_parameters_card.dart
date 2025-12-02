import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/models.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/utils.dart';
import 'package:misty_breez/routes/routes.dart';

class NwcConnectionParametersCard extends StatelessWidget {
  final NwcConnectionModel connection;

  const NwcConnectionParametersCard({required this.connection, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    // Don't show card if no parameters are set
    if (connection.periodicBudget == null && connection.expiresAt == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: themeData.customData.surfaceBgColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            <Widget>[
                if (connection.periodicBudget != null)
                  StatusItem(
                    label: 'Budget ${connection.periodicBudget!.renewsAt != null ? 'Renewal' : 'Amount'}',
                    value: _formatBudgetRenewal(connection.periodicBudget!),
                  ),
                StatusItem(label: 'Expiry Time', value: _formatExpiryTime(connection.expiresAt)),
              ].expand((Widget widget) sync* {
                yield widget;
                yield const Divider(
                  height: 8.0,
                  color: Color.fromRGBO(40, 59, 74, 0.5),
                  indent: 0.0,
                  endIndent: 0.0,
                );
              }).toList()
              ..removeLast(),
      ),
    );
  }

  String _formatBudgetRenewal(PeriodicBudget periodicBudget) {
    final int maxBudgetSat = periodicBudget.maxBudgetSat.toInt();
    final String amount = BitcoinCurrency.sat.format(maxBudgetSat);

    if (periodicBudget.renewsAt != null) {
      final int renewalIntervalMins = ((periodicBudget.renewsAt! - periodicBudget.updatedAt) / 60).round();
      final String? interval = _formatResetInterval(renewalIntervalMins);
      return interval == null ? amount : '$amount / $interval';
    }

    return amount;
  }

  String? _formatResetInterval(int renewalTimeMins) {
    switch (renewalTimeMins) {
      case 0:
        return null;
      case 1440:
        return 'day';
      case 10080:
        return 'week';
      case 43200:
        return 'month';
      case 525600:
        return 'year';
      default:
        return null;
    }
  }

  String _formatExpiryTime(int? expiresAt) {
    if (expiresAt == null) {
      return 'Never';
    }
    return BreezDateUtils.formatYearMonthDayHourMinuteSecond(
      DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
    );
  }
}
