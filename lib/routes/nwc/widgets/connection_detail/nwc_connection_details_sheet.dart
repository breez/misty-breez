import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/widgets/error_dialog.dart';
import 'package:misty_breez/routes/nwc/widgets/connection_item/nwc_connection_item_header.dart';

final Logger _logger = Logger('NwcConnectionDetailsSheet');

Future<dynamic> showNwcConnectionDetailsSheet(
  BuildContext context, {
  required NwcConnectionModel connection,
}) async {
  final NwcCubit nwcCubit = context.read<NwcCubit>();

  return await Navigator.push(
    context,
    MaterialPageRoute<dynamic>(
      builder: (BuildContext context) {
        return BlocProvider<NwcCubit>.value(
          value: nwcCubit,
          child: NwcConnectionDetailsSheet(connection: connection),
        );
      },
    ),
  );
}

class NwcConnectionDetailsSheet extends StatelessWidget {
  final NwcConnectionModel connection;

  NwcConnectionDetailsSheet({required this.connection, super.key}) {
    _logger.info('NwcConnectionDetailsSheet for connection: ${connection.name}');
  }

  bool _isExpiringWithinWeek(NwcConnectionModel connection) {
    if (connection.expiresAt == null) {
      return false;
    }
    final DateTime expiryDate = DateTime.fromMillisecondsSinceEpoch(connection.expiresAt! * 1000);
    final Duration diff = expiryDate.difference(DateTime.now());
    return diff.inDays <= 7 && diff.inDays >= 0;
  }

  bool _existsIn(NwcState state, NwcConnectionModel target) =>
      state.connections.any((NwcConnectionModel c) => c.name == target.name);

  Future<void> _confirmAndDeleteConnection(BuildContext context, String connectionName) async {
    final bool? confirmed = await promptAreYouSure(
      context,
      title: 'Delete Connection',
      body: Text('Are you sure you want to delete "$connectionName"? This action cannot be undone.'),
    );

    if (confirmed == true && context.mounted) {
      await context.read<NwcCubit>().deleteConnection(connectionName);
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return BlocConsumer<NwcCubit, NwcState>(
      listenWhen: (NwcState previous, NwcState current) {
        final bool prevExists = _existsIn(previous, connection);
        final bool currExists = _existsIn(current, connection);
        return (previous.isLoading && !current.isLoading) || (prevExists && !currExists);
      },
      listener: (BuildContext context, NwcState state) {
        final bool exists = _existsIn(state, connection);
        if (!exists && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      builder: (BuildContext context, NwcState state) {
        final NwcConnectionModel updatedConnection = state.connections.firstWhere(
          (NwcConnectionModel c) => c.name == connection.name,
          orElse: () => connection,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Connection Details'),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: state.isLoading
                    ? null
                    : () => _confirmAndDeleteConnection(context, updatedConnection.name),
                tooltip: 'Delete connection',
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 32.0, bottom: 0.0),
                    child: Center(
                      child: Column(
                        children: <Widget>[
                          NwcConnectionItemHeader(
                            connectionName: updatedConnection.name,
                            hasPeriodicBudget: updatedConnection.periodicBudget != null,
                            isExpiringWithinWeek: _isExpiringWithinWeek(updatedConnection),
                            centerTitle: true,
                            actions: <Widget>[
                              IconButton(
                                icon: const Icon(Icons.qr_code, size: 20.0, color: Colors.white),
                                onPressed: () =>
                                    NwcQrDialog.show(context, updatedConnection.connectionString),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Show QR',
                              ),
                              const SizedBox(width: 8.0),
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, size: 24.0, color: Colors.white),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(
                                    context,
                                  ).pushNamed(NwcEditConnectionPage.routeName, arguments: updatedConnection);
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Edit',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: ShapeDecoration(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      color: themeData.customData.surfaceBgColor,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    child: Column(
                      children: <Widget>[
                        if (updatedConnection.periodicBudget != null || updatedConnection.expiresAt != null)
                          NwcConnectionParametersCard(connection: updatedConnection),
                        if (updatedConnection.periodicBudget != null || updatedConnection.expiresAt != null)
                          const Divider(
                            height: 32.0,
                            color: Color.fromRGBO(40, 59, 74, 0.5),
                            indent: 0.0,
                            endIndent: 0.0,
                          ),
                        NwcConnectionUriCard(connectionString: updatedConnection.connectionString),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
