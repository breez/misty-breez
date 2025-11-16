import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/cubit/nwc/nwc_state.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';
import 'package:service_injector/service_injector.dart';

class NwcConnectionDetailPage extends StatelessWidget {
  static const String routeName = '/nwc/connection/detail';

  final NwcConnectionModel connection;

  const NwcConnectionDetailPage({required this.connection, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Scaffold(
      appBar: AppBar(leading: const back_button.BackButton(), title: Text(connection.name)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Connection Name Section
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: themeData.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Connection Name',
                      style: themeData.textTheme.labelMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(connection.name, style: themeData.textTheme.titleLarge),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Connection URI Section
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: themeData.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Connection URI',
                      style: themeData.textTheme.labelMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      connection.connectionString,
                      style: themeData.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace', fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(IconData(0xe90b, fontFamily: 'icomoon'), size: 20.0),
                      label: const Text('Copy'),
                      onPressed: () => _copyConnectionString(context),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Delete Button
              BlocListener<NwcCubit, NwcState>(
                listenWhen: (NwcState previous, NwcState current) {
                  // Only listen when loading finishes after a delete operation
                  return previous.isLoading &&
                      !current.isLoading &&
                      !current.connections.any((c) => c.name == connection.name);
                },
                listener: (BuildContext context, NwcState state) {
                  // Connection was successfully deleted (no longer in list)
                  Navigator.of(context).pop();
                },
                child: BlocBuilder<NwcCubit, NwcState>(
                  builder: (BuildContext context, NwcState state) {
                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: themeData.colorScheme.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: state.isLoading ? null : () => _deleteConnection(context),
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Delete Connection', style: TextStyle(color: themeData.colorScheme.error)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyConnectionString(BuildContext context) {
    ServiceInjector().deviceClient.setClipboardText(connection.connectionString);
    showFlushbar(context, message: 'Connection code copied', duration: const Duration(seconds: 3));
  }

  Future<void> _deleteConnection(BuildContext context) async {
    final bool? confirmed = await promptAreYouSure(
      context,
      title: 'Delete Connection',
      body: Text('Are you sure you want to delete "${connection.name}"?'),
    );

    if (confirmed == true && context.mounted) {
      context.read<NwcCubit>().deleteConnection(connection.name);
    }
  }
}
