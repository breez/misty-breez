import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/models/currency.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/utils/date/breez_date_utils.dart';

class NwcConnectionItem extends StatelessWidget {
  final NwcConnectionModel connection;

  const NwcConnectionItem({required this.connection, super.key});

  String? _formatResetInterval(int resetTimeSec) {
    switch (resetTimeSec) {
      case 0:
        return null;
      case 86400:
        return 'day';
      case 604800:
        return 'week';
      case 2592000:
        return 'month';
      case 31536000:
        return 'year';
      default:
        return null;
    }
  }

  Widget? _buildSubtitle(ThemeData themeData) {
    final List<Widget> rows = <Widget>[];

    if (connection.periodicBudget != null) {
      final String amount = BitcoinCurrency.sat.format(connection.periodicBudget!.maxBudgetSat.toInt());
      final String? interval = _formatResetInterval(connection.periodicBudget!.resetTimeSec);
      final String budgetText = interval == null ? amount : '$amount / $interval';

      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  'Budget renewal',
                  style: themeData.textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  budgetText,
                  style: themeData.textTheme.bodySmall?.copyWith(color: Colors.white70, fontSize: 12),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (connection.expiryTimeSec != null) {
      final DateTime expiryDate = DateTime.now().add(Duration(seconds: connection.expiryTimeSec!));
      final String formattedExpiry = BreezDateUtils.formatYearMonthDayHourMinuteSecond(expiryDate);
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            'Connection will expire on $formattedExpiry.',
            style: themeData.textTheme.bodySmall?.copyWith(color: Colors.white70, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      return null;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Future<void> _deleteConnection(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0.0),
          title: const Text('Are you sure you want to delete this connection?'),
          content: const Text('Connected apps will no longer be able to use this connection.'),
          actions: <Widget>[
            TextButton(
              child: const Text('CANCEL'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('CONFIRM'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<NwcCubit>().deleteConnection(connection.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: themeData.customData.surfaceBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        title: Text(
          connection.name,
          style: themeData.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: _buildSubtitle(themeData),
        trailing: IconButton(
          icon: const Icon(Icons.power_off_outlined),
          onPressed: () => _deleteConnection(context),
          tooltip: 'Disconnect',
        ),
        onTap: () {
          Navigator.of(context).pushNamed(NwcConnectionDetailPage.routeName, arguments: connection);
        },
      ),
    );
  }
}
