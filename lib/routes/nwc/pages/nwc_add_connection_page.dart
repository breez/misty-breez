import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/nwc/pages/nwc_page.dart';
import 'package:misty_breez/routes/nwc/widgets/connection_views/nwc_add_connection_view.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';

class NwcAddConnectionPage extends StatefulWidget {
  static const String routeName = '/nwc/connection/add';

  const NwcAddConnectionPage({super.key});

  @override
  State<NwcAddConnectionPage> createState() => _NwcAddConnectionPageState();
}

class _NwcAddConnectionPageState extends State<NwcAddConnectionPage> {
  bool _connectionCreated = false;
  final GlobalKey<NwcAddConnectionViewState> _viewKey = GlobalKey<NwcAddConnectionViewState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const back_button.BackButton(), title: const Text('Connect a new app')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: BlocBuilder<NwcCubit, NwcState>(
            buildWhen: (NwcState previous, NwcState current) => previous.isLoading != current.isLoading,
            builder: (BuildContext context, NwcState state) {
              return SingleChildScrollView(
                child: NwcAddConnectionView(
                  key: _viewKey,
                  onConnectionCreated: () {
                    setState(() {
                      _connectionCreated = true;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: BlocBuilder<NwcCubit, NwcState>(
          builder: (BuildContext context, NwcState state) {
            if (_connectionCreated) {
              return SingleButtonBottomBar(
                stickToBottom: true,
                text: 'CLOSE',
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(NwcPage.routeName);
                },
              );
            }
            return SingleButtonBottomBar(
              stickToBottom: true,
              text: 'CONNECT',
              loading: state.isLoading,
              onPressed: () {
                _viewKey.currentState?.createConnection();
              },
            );
          },
        ),
      ),
    );
  }
}
