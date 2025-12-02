import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';

class NwcConnectionDetailPage extends StatefulWidget {
  static const String routeName = '/nwc/connection/detail';

  final NwcConnectionModel connection;

  const NwcConnectionDetailPage({required this.connection, super.key});

  @override
  State<NwcConnectionDetailPage> createState() => _NwcConnectionDetailPageState();
}

class _NwcConnectionDetailPageState extends State<NwcConnectionDetailPage> {
  late NwcConnectionModel _connection;

  @override
  void initState() {
    super.initState();
    _connection = widget.connection;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NwcCubit, NwcState>(
      listenWhen: (NwcState previous, NwcState current) {
        // Listen when loading completes or connection is deleted
        if (previous.isLoading && !current.isLoading) {
          return true;
        }
        return _isConnectionDeleted(current) && !_isConnectionDeleted(previous);
      },
      listener: (BuildContext context, NwcState state) {
        if (_isConnectionDeleted(state)) {
          _handleConnectionDeleted();
          return;
        }
        _updateConnectionIfChanged(state);
      },
      child: Scaffold(
        appBar: AppBar(leading: const back_button.BackButton(), title: Text(_connection.name)),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  NwcConnectionInfoCard(connectionName: _connection.name),
                  const SizedBox(height: 16),
                  NwcConnectionParametersCard(connection: _connection),
                  const SizedBox(height: 16),
                  NwcConnectionUriCard(
                    connectionString: _connection.connectionString,
                    onShowQr: () => NwcQrDialog.show(context, _connection.connectionString),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BlocBuilder<NwcCubit, NwcState>(
          builder: (BuildContext context, NwcState state) {
            return SingleButtonBottomBar(
              text: 'EDIT CONNECTION',
              loading: state.isLoading,
              onPressed: () => showNwcConnectBottomSheet(context, existingConnection: _connection),
            );
          },
        ),
      ),
    );
  }

  bool _isConnectionDeleted(NwcState state) {
    return !state.connections.any((NwcConnectionModel c) => c.name == _connection.name);
  }

  void _handleConnectionDeleted() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _updateConnectionIfChanged(NwcState state) {
    final NwcConnectionModel? updatedConnection = _findUpdatedConnection(state);
    if (updatedConnection != null && mounted) {
      setState(() {
        _connection = updatedConnection;
      });
    }
  }

  NwcConnectionModel? _findUpdatedConnection(NwcState state) {
    return state.connections.cast<NwcConnectionModel?>().firstWhere(
      (NwcConnectionModel? c) => c?.name == _connection.name,
      orElse: () => null,
    );
  }
}
