import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/error_dialog.dart';

class NwcConnectionDetailPage extends StatelessWidget {
  static const String routeName = '/nwc/connection/detail';

  final NwcConnectionModel connection;

  const NwcConnectionDetailPage({required this.connection, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NwcCubit, NwcState>(
      listenWhen: (NwcState previous, NwcState current) {
        final bool prevExists = _existsIn(previous, connection);
        final bool currExists = _existsIn(current, connection);
        return (previous.isLoading && !current.isLoading) || (prevExists && !currExists);
      },
      listener: (BuildContext context, NwcState state) {
        final bool exists = _existsIn(state, connection);
        if (!exists && context.mounted) {
          Navigator.of(context).pushReplacementNamed(NwcPage.routeName);
        }
      },
      builder: (BuildContext context, NwcState state) {
        final NwcConnectionModel updatedConnection = state.connections.firstWhere(
          (NwcConnectionModel c) => c.name == connection.name,
          orElse: () => connection,
        );

        return Scaffold(
          appBar: AppBar(
            leading: const back_button.BackButton(),
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
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    decoration: ShapeDecoration(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      color: Theme.of(context).customData.surfaceBgColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        NwcConnectionItemHeader(
                          connectionName: updatedConnection.name,
                          hasContent: true,
                          centerTitle: true,
                          actions: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.qr_code, size: 20.0, color: Colors.white),
                              onPressed: () => NwcQrDialog.show(context, updatedConnection.connectionString),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Show QR',
                            ),
                            const SizedBox(width: 8.0),
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded, size: 24.0, color: Colors.white),
                              onPressed: () {
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
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                <Widget>[
                                    if (updatedConnection.periodicBudget != null ||
                                        updatedConnection.expiresAt != null)
                                      NwcConnectionParametersCard(connection: updatedConnection),
                                    NwcConnectionUriCard(
                                      connectionString: updatedConnection.connectionString,
                                    ),
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
                        ),
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
    }
  }
}
