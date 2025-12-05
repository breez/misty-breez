import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/nwc/widgets/connection_views/nwc_edit_connection_view.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';

class NwcEditConnectionPage extends StatefulWidget {
  static const String routeName = '/nwc/connection/edit';

  final NwcConnectionModel connection;

  const NwcEditConnectionPage({required this.connection, super.key});

  @override
  State<NwcEditConnectionPage> createState() => _NwcEditConnectionPageState();
}

class _NwcEditConnectionPageState extends State<NwcEditConnectionPage> {
  final GlobalKey<NwcEditConnectionViewState> _viewKey = GlobalKey<NwcEditConnectionViewState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const back_button.BackButton(), title: const Text('Edit Connection')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: BlocBuilder<NwcCubit, NwcState>(
            buildWhen: (NwcState previous, NwcState current) => previous.isLoading != current.isLoading,
            builder: (BuildContext context, NwcState state) {
              return SingleChildScrollView(
                child: NwcEditConnectionView(key: _viewKey, existingConnection: widget.connection),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BlocBuilder<NwcCubit, NwcState>(
        builder: (BuildContext context, NwcState state) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: SingleButtonBottomBar(
              stickToBottom: true,
              text: 'SAVE',
              loading: state.isLoading,
              onPressed: () {
                _viewKey.currentState?.editConnection();
              },
            ),
          );
        },
      ),
    );
  }
}
