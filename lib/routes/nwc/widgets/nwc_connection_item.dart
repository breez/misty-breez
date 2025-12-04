import 'package:flutter/material.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/routes/nwc/widgets/connection_item/connection_item.dart';
import 'package:misty_breez/routes/nwc/widgets/connection_detail/nwc_connection_details_sheet.dart';
import 'package:misty_breez/theme/src/theme.dart';

class NwcConnectionItem extends StatelessWidget {
  final NwcConnectionModel connection;

  const NwcConnectionItem({required this.connection, super.key});

  bool get _isExpiringWithinWeek {
    if (connection.expiresAt == null) {
      return false;
    }
    final DateTime expiryDate = DateTime.fromMillisecondsSinceEpoch(connection.expiresAt! * 1000);
    final Duration diff = expiryDate.difference(DateTime.now());
    return diff.inDays <= 7 && diff.inDays >= 0;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      color: themeData.customData.surfaceBgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      child: InkWell(
        onTap: () {
          showNwcConnectionDetailsSheet(context, connection: connection);
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            NwcConnectionItemHeader(
              connectionName: connection.name,
              hasPeriodicBudget: connection.periodicBudget != null,
              isExpiringWithinWeek: _isExpiringWithinWeek,
            ),
            NwcConnectionItemContent(connection: connection, isExpiringWithinWeek: _isExpiringWithinWeek),
          ],
        ),
      ),
    );
  }
}
