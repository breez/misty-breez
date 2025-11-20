import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';

class NwcPage extends StatefulWidget {
  static const String routeName = '/nwc';

  const NwcPage({super.key});

  @override
  State<NwcPage> createState() => _NwcPageState();
}

class _NwcPageState extends State<NwcPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRefreshTimer();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (mounted) {
        final NwcCubit nwcCubit = context.read<NwcCubit>();
        nwcCubit.loadConnections();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const back_button.BackButton(), title: const Text('Nostr Wallet Connect')),
      body: BlocBuilder<NwcCubit, NwcState>(
        builder: (BuildContext context, NwcState state) {
          if (state.isLoading && state.connections.isEmpty) {
            return const CenteredLoader(color: Colors.white);
          }

          if (state.error != null && state.connections.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: <Widget>[
              Expanded(
                child: state.connections.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Icon(Icons.link_off, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text('No NWC connections', style: Theme.of(context).textTheme.titleLarge),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: state.connections.length,
                        itemBuilder: (BuildContext context, int index) {
                          return NwcConnectionItem(connection: state.connections[index]);
                        },
                      ),
              ),
              SingleButtonBottomBar(
                text: 'CONNECT',
                stickToBottom: true,
                onPressed: () {
                  final NwcCubit nwcCubit = context.read<NwcCubit>();
                  showNwcConnectBottomSheet(context, nwcCubit: nwcCubit);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
