import 'package:flutter/material.dart';
import 'package:l_breez/routes/dev/widget/command.dart';
import 'package:l_breez/widgets/loader.dart';

class CommandList extends StatelessWidget {
  final bool loading;
  final bool defaults;
  final List<TextSpan> fallback;
  final TextStyle fallbackTextStyle;
  final TextEditingController inputController;
  final FocusNode focusNode;

  const CommandList({
    required this.inputController,
    required this.focusNode,
    super.key,
    this.loading = false,
    this.defaults = false,
    this.fallback = const <TextSpan>[],
    this.fallbackTextStyle = const TextStyle(),
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    if (loading) {
      return const Center(
        child: Loader(
          color: Colors.white,
        ),
      );
    }

    if (defaults) {
      return Theme(
        data: themeData.copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ListView(
          children: <Widget>[
            ExpansionTile(
              title: const Text('General'),
              children: <Widget>[
                Command(
                  'generateDiagnosticData',
                  (String c) => _onCommand(context, c),
                ),
                Command(
                  'getInfo',
                  (String c) => _onCommand(context, c),
                ),
                Command(
                  'listPeers',
                  (String c) => _onCommand(context, c),
                ),
                Command(
                  'listPeerChannels',
                  (String c) => _onCommand(context, c),
                ),
                Command(
                  'listFunds',
                  (String c) => _onCommand(context, c),
                ),
                Command(
                  'listPayments',
                  (String c) => _onCommand(context, c),
                ),
                Command(
                  'listInvoices',
                  (String c) => _onCommand(context, c),
                ),
                Command(
                  'closeAllChannels',
                  (String c) => _onCommand(context, c),
                ),
                Command(
                  'stop',
                  (String c) => _onCommand(context, c),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return ListView(
      children: <Widget>[
        RichText(
          text: TextSpan(
            style: fallbackTextStyle,
            children: fallback,
          ),
        ),
      ],
    );
  }

  void _onCommand(BuildContext context, String command) {
    inputController.text = command;
    FocusScope.of(context).requestFocus(focusNode);
  }
}
