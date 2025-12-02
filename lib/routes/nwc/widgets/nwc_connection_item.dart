import 'package:flutter/material.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/routes/nwc/widgets/connection_item/connection_item.dart';
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
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: themeData.customData.paymentListBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(NwcConnectionDetailPage.routeName, arguments: connection);
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            NwcConnectionItemHeader(
              connectionName: connection.name,
              isExpiringWithinWeek: _isExpiringWithinWeek,
            ),
            NwcConnectionItemContent(connection: connection, isExpiringWithinWeek: _isExpiringWithinWeek),
          ],
        ),
      ),
    );
  }
}
