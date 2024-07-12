import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:breez_logger/breez_logger.dart';
import 'package:breez_preferences/breez_preferences.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/dev/command_line_interface.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

final _log = Logger("DevelopersView");

bool allowRebroadcastRefunds = false;

class Choice {
  const Choice({
    required this.title,
    required this.icon,
    required this.function,
  });

  final String title;
  final IconData icon;
  final Function(BuildContext context) function;
}

class DevelopersView extends StatefulWidget {
  const DevelopersView({super.key});

  @override
  State<DevelopersView> createState() => _DevelopersViewState();
}

class _DevelopersViewState extends State<DevelopersView> {
  final _preferences = const BreezPreferences();
  var bugReportBehavior = BugReportBehavior.prompt;

  @override
  void initState() {
    super.initState();
    _preferences
        .getBugReportBehavior()
        .then((value) => bugReportBehavior = value, onError: (e) => _log.warning(e));
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    final texts = getSystemAppLocalizations();
    final themeData = Theme.of(context);

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const back_button.BackButton(),
        title: Text(texts.home_drawer_item_title_developers),
        actions: [
          PopupMenuButton<Choice>(
            onSelected: (c) => c.function(context),
            color: themeData.colorScheme.surface,
            icon: Icon(
              Icons.more_vert,
              color: themeData.iconTheme.color,
            ),
            itemBuilder: (context) => [
              if (kDebugMode)
                Choice(
                  title: "Export Keys",
                  icon: Icons.phone_android,
                  function: _exportKeys,
                ),
              Choice(
                title: "Share Logs",
                icon: Icons.share,
                function: (_) => shareLog(),
              ),
              if (bugReportBehavior != BugReportBehavior.prompt)
                Choice(
                  title: "Enable Failure Prompt",
                  icon: Icons.bug_report,
                  function: (_) {
                    _preferences.setBugReportBehavior(BugReportBehavior.prompt).then(
                        (value) => setState(
                              () {
                                bugReportBehavior = BugReportBehavior.prompt;
                              },
                            ),
                        onError: (e) => _log.warning(e));
                  },
                ),
            ]
                .map(
                  (choice) => PopupMenuItem<Choice>(
                    value: choice,
                    child: Text(
                      choice.title,
                      style: themeData.textTheme.labelLarge,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      // TODO: Liquid - Remove Absorb Pointer once execute_command API is implemented
      body: Container(
        color: const Color(0xFF696969),
        child: AbsorbPointer(
          absorbing: true,
          child: CommandLineInterface(scaffoldKey: scaffoldKey),
        ),
      ),
    );
  }

  void _exportKeys(BuildContext context) async {
    final accountCubit = context.read<AccountCubit>();
    final appDir = await getApplicationDocumentsDirectory();
    final encoder = ZipFileEncoder();
    final zipFilePath = "${appDir.path}/l-breez-keys.zip";
    encoder.create(zipFilePath);
    final List<File> credentialFiles = await accountCubit.exportCredentialFiles();
    for (var credentialFile in credentialFiles) {
      final bytes = await credentialFile.readAsBytes();
      encoder.addArchiveFile(
        ArchiveFile(basename(credentialFile.path), bytes.length, bytes),
      );
    }
    final storageFilePath = "${appDir.path}/storage.sql";
    final storageFile = File(storageFilePath);
    encoder.addFile(storageFile);
    encoder.close();
    final zipFile = XFile(zipFilePath);
    Share.shareXFiles([zipFile]);
  }
}
