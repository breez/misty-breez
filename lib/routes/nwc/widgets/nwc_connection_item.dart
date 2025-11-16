import 'package:flutter/material.dart';
import 'package:misty_breez/cubit/nwc/nwc_state.dart';
import 'package:misty_breez/routes/routes.dart';

class NwcConnectionItem extends StatelessWidget {
  final NwcConnectionModel connection;

  const NwcConnectionItem({required this.connection, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: themeData.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        title: Text(connection.name),
        onTap: () {
          Navigator.of(context).pushNamed(NwcConnectionDetailPage.routeName, arguments: connection);
        },
      ),
    );
  }
}
