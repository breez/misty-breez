import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';

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
          Navigator.of(context).pop();
        }
      },
      builder: (BuildContext context, NwcState state) {
        final NwcConnectionModel updated = state.connections.firstWhere(
          (NwcConnectionModel c) => c.name == connection.name,
          orElse: () => connection,
        );

        return Scaffold(
          appBar: AppBar(leading: const back_button.BackButton(), title: Text(updated.name)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Card(
                    color: Theme.of(context).customData.surfaceBgColor,
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            <Widget>[
                                NwcConnectionInfoCard(connectionName: updated.name),
                                NwcConnectionParametersCard(connection: updated),
                                NwcConnectionUriCard(
                                  connectionString: updated.connectionString,
                                  onShowQr: () => NwcQrDialog.show(context, updated.connectionString),
                                ),
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
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SingleButtonBottomBar(
            text: 'EDIT CONNECTION',
            loading: state.isLoading,
            onPressed: () => showNwcConnectBottomSheet(context, existingConnection: updated),
          ),
        );
      },
    );
  }

  bool _existsIn(NwcState state, NwcConnectionModel target) =>
      state.connections.any((NwcConnectionModel c) => c.name == target.name);
}
