import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';

class NwcConnectionItem extends StatelessWidget {
  final NwcConnectionModel connection;

  const NwcConnectionItem({required this.connection, super.key});

  Future<void> _deleteConnection(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 0.0),
          title: const Text('Disconnect Connection'),
          content: const Text(
            'Are you sure you want to delete this connection? Connected apps will no longer be able to use this connection.',
          ),
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
        title: Text(connection.name),
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
