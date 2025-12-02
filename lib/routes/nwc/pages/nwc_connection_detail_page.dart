import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';

import 'package:misty_breez/routes/nwc/widgets/connection_item/nwc_connection_item_header.dart';

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
        final NwcConnectionModel updatedConnection = state.connections.firstWhere(
          (NwcConnectionModel c) => c.name == connection.name,
          orElse: () => connection,
        );

        return Scaffold(
          appBar: AppBar(leading: const back_button.BackButton(), title: const Text('Connection Details')),
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
                          hasPeriodicBudget: updatedConnection.periodicBudget != null,
                          isExpiringWithinWeek: _isExpiringWithinWeek(updatedConnection),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                <Widget>[
                                    if (updatedConnection.periodicBudget != null ||
                                        updatedConnection.expiresAt != null)
                                      NwcConnectionParametersCard(connection: updatedConnection),
                                    NwcConnectionUriCard(
                                      connectionString: updatedConnection.connectionString,
                                      onShowQr: () =>
                                          NwcQrDialog.show(context, updatedConnection.connectionString),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SingleButtonBottomBar(
            text: 'EDIT CONNECTION',
            loading: state.isLoading,
            onPressed: () => showNwcConnectBottomSheet(context, existingConnection: updatedConnection),
          ),
        );
      },
    );
  }

  bool _existsIn(NwcState state, NwcConnectionModel target) =>
      state.connections.any((NwcConnectionModel c) => c.name == target.name);

  bool _isExpiringWithinWeek(NwcConnectionModel connection) {
    if (connection.expiresAt == null) {
      return false;
    }
    final DateTime expiryDate = DateTime.fromMillisecondsSinceEpoch(connection.expiresAt! * 1000);
    final Duration diff = expiryDate.difference(DateTime.now());
    return diff.inDays <= 7 && diff.inDays >= 0;
  }
}
