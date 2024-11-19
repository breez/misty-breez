import 'dart:convert';
import 'dart:io';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/routes/dev/widget/command_list.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:service_injector/service_injector.dart';
import 'package:share_plus/share_plus.dart';

final Logger _logger = Logger('CommandsList');

class CommandLineInterface extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const CommandLineInterface({required this.scaffoldKey, super.key});

  @override
  State<CommandLineInterface> createState() => _CommandLineInterfaceState();
}

class _CommandLineInterfaceState extends State<CommandLineInterface> {
  //final _breezSdkLiquid = ServiceInjector().breezSdkLiquid;

  final TextEditingController _cliInputController = TextEditingController();
  final FocusNode _cliEntryFocusNode = FocusNode();

  String _cliText = '';
  String _lastCommand = '';
  TextStyle _cliTextStyle = smallTextStyle;
  bool _showDefaultCommands = true;
  bool isLoading = false;
  List<TextSpan> _richCliText = <TextSpan>[];

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Row(
            children: <Widget>[
              Flexible(
                child: TextField(
                  focusNode: _cliEntryFocusNode,
                  controller: _cliInputController,
                  decoration: InputDecoration(
                    hintText: texts.developers_page_cli_hint,
                  ),
                  onSubmitted: (String command) {
                    _sendCommand(command);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.play_arrow),
                tooltip: texts.developers_page_cli_run_tooltip,
                onPressed: () {
                  _sendCommand(_cliInputController.text);
                },
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: texts.developers_page_cli_clear_tooltip,
                onPressed: () {
                  setState(() {
                    _cliInputController.clear();
                    _showDefaultCommands = true;
                    _lastCommand = '';
                    _cliText = '';
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
            child: Container(
              padding: _showDefaultCommands ? const EdgeInsets.all(0.0) : const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                border: _showDefaultCommands
                    ? null
                    : Border.all(
                        color: const Color(0x80FFFFFF),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _showDefaultCommands
                      ? Container()
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.content_copy),
                              tooltip: texts.developers_page_cli_result_copy_tooltip,
                              iconSize: 19.0,
                              onPressed: () {
                                ServiceInjector().deviceClient.setClipboardText(_cliText);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      texts.developers_page_cli_result_copied,
                                      style: snackBarStyle,
                                    ),
                                    backgroundColor: snackBarBackgroundColor,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.share),
                              iconSize: 19.0,
                              tooltip: texts.developers_page_cli_result_share_tooltip,
                              onPressed: () {
                                _shareFile(
                                  _lastCommand.split(' ')[0],
                                  _cliText,
                                );
                              },
                            ),
                          ],
                        ),
                  Expanded(
                    child: CommandList(
                      loading: isLoading,
                      defaults: _showDefaultCommands,
                      fallback: _richCliText,
                      fallbackTextStyle: _cliTextStyle,
                      inputController: _cliInputController,
                      focusNode: _cliEntryFocusNode,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _sendCommand(String command) async {
    _logger.info('Send command: $command');
    final BreezTranslations texts = context.texts();

    if (command.isNotEmpty) {
      FocusScope.of(context).requestFocus(FocusNode());
      setState(() {
        _lastCommand = command;
        isLoading = true;
      });
      const JsonEncoder encoder = JsonEncoder.withIndent('    ');
      try {
        final List<String> commandArgs = command.split(RegExp(r'\s'));
        if (commandArgs.isEmpty) {
          _logger.info('Command args is empty, skipping');
          setState(() {
            isLoading = false;
          });
          return;
        }
        late String reply;
        switch (commandArgs[0]) {
          case 'generateDiagnosticData':
          case 'getInfo':
          case 'listPeers':
          case 'listPeerChannels':
          case 'listFunds':
          case 'listPayments':
          case 'listInvoices':
          case 'closeAllChannels':
          case 'stop':
            final String command = commandArgs[0].toLowerCase();
            _logger.info('executing command: $command');
            // TODO(erdemyerebasmaz): Liquid - Add execute_commands to Dart bindings
            const String answer = ''; // await _breezSdkLiquid.executeCommand(command: command);
            _logger.info('Received answer: $answer');
            reply = encoder.convert(answer);
            _logger.info('Reply: $reply');
            break;
          default:
            throw texts.developers_page_cli_unsupported_command;
        }
        setState(() {
          _showDefaultCommands = false;
          _cliTextStyle = smallTextStyle;
          _cliText = reply;
          _richCliText = <TextSpan>[TextSpan(text: _cliText)];
          isLoading = false;
        });
      } catch (error) {
        _logger.warning('Error happening', error);
        setState(() {
          _showDefaultCommands = false;
          _cliText = error.toString();
          _cliTextStyle = warningStyle;
          _richCliText = <TextSpan>[TextSpan(text: _cliText)];
          isLoading = false;
        });
      }
      setState(() => isLoading = false);
    }
  }

  void _shareFile(String command, String text) async {
    Directory tempDir = await getTemporaryDirectory();
    tempDir = await tempDir.createTemp('command');
    final String filePath = '${tempDir.path}/$command.json';
    final File file = File(filePath);
    await file.writeAsString(text, flush: true);
    final XFile xFile = XFile(filePath);
    Share.shareXFiles(<XFile>[xFile]);
  }
}
