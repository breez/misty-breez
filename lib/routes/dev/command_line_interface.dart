import 'dart:convert';
import 'dart:io';

import 'package:l_breez/routes/dev/widget/command_list.dart';
import 'package:l_breez/services/injector.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

final _log = Logger("CommandsList");

class CommandLineInterface extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const CommandLineInterface({super.key, required this.scaffoldKey});

  @override
  State<CommandLineInterface> createState() => _CommandLineInterfaceState();
}

class _CommandLineInterfaceState extends State<CommandLineInterface> {
  //final _breezSDK = ServiceInjector().breezSDK;

  final _cliInputController = TextEditingController();
  final FocusNode _cliEntryFocusNode = FocusNode();

  String _cliText = '';
  String _lastCommand = '';
  TextStyle _cliTextStyle = theme.smallTextStyle;
  bool _showDefaultCommands = true;
  bool isLoading = false;
  var _richCliText = <TextSpan>[];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Row(
            children: <Widget>[
              Flexible(
                child: TextField(
                  focusNode: _cliEntryFocusNode,
                  controller: _cliInputController,
                  decoration: const InputDecoration(
                    hintText: 'Enter a command or use the links below',
                  ),
                  onSubmitted: (command) {
                    _sendCommand(command);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.play_arrow),
                tooltip: 'Run',
                onPressed: () {
                  _sendCommand(_cliInputController.text);
                },
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear',
                onPressed: () {
                  setState(() {
                    _cliInputController.clear();
                    _showDefaultCommands = true;
                    _lastCommand = '';
                    _cliText = "";
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
            child: Container(
              padding: _showDefaultCommands ? const EdgeInsets.all(0.0) : const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                border: _showDefaultCommands
                    ? null
                    : Border.all(
                        width: 1.0,
                        color: const Color(0x80FFFFFF),
                      ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _showDefaultCommands
                      ? Container()
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            IconButton(
                              icon: const Icon(Icons.content_copy),
                              tooltip: 'Copy to Clipboard',
                              iconSize: 19.0,
                              onPressed: () {
                                ServiceInjector().device.setClipboardText(_cliText);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Copied to clipboard.',
                                      style: theme.snackBarStyle,
                                    ),
                                    backgroundColor: theme.snackBarBackgroundColor,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.share),
                              iconSize: 19.0,
                              tooltip: 'Share',
                              onPressed: () {
                                _shareFile(
                                  _lastCommand.split(" ")[0],
                                  _cliText,
                                );
                              },
                            )
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
    _log.info("Send command: $command");
    if (command.isNotEmpty) {
      FocusScope.of(context).requestFocus(FocusNode());
      setState(() {
        _lastCommand = command;
        isLoading = true;
      });
      const JsonEncoder encoder = JsonEncoder.withIndent('    ');
      try {
        var commandArgs = command.split(RegExp(r"\s"));
        if (commandArgs.isEmpty) {
          _log.info("Command args is empty, skipping");
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
            final command = commandArgs[0].toLowerCase();
            _log.info("executing command: $command");
            const answer = ""; // await _breezSDK.executeCommand(command: command);
            _log.info("Received answer: $answer");
            reply = encoder.convert(answer);
            _log.info("Reply: $reply");
            break;
          default:
            throw "This command is not supported yet.";
        }
        setState(() {
          _showDefaultCommands = false;
          _cliTextStyle = theme.smallTextStyle;
          _cliText = reply;
          _richCliText = <TextSpan>[TextSpan(text: _cliText)];
          isLoading = false;
        });
      } catch (error) {
        _log.warning("Error happening", error);
        setState(() {
          _showDefaultCommands = false;
          _cliText = error.toString();
          _cliTextStyle = theme.warningStyle;
          _richCliText = <TextSpan>[TextSpan(text: _cliText)];
          isLoading = false;
        });
      }
      setState(() => isLoading = false);
    }
  }

  void _shareFile(String command, String text) async {
    Directory tempDir = await getTemporaryDirectory();
    tempDir = await tempDir.createTemp("command");
    String filePath = '${tempDir.path}/$command.json';
    File file = File(filePath);
    await file.writeAsString(text, flush: true);
    final xFile = XFile(filePath);
    Share.shareXFiles([xFile]);
  }
}
