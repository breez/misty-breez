import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:breez_logger/breez_logger.dart';
import 'package:breez_preferences/breez_preferences.dart';
import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:credentials_manager/credentials_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/dev/command_line_interface.dart';
import 'package:l_breez/utils/exceptions.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/flushbar.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:service_injector/service_injector.dart';
import 'package:share_plus/share_plus.dart';

final Logger _logger = Logger('DevelopersView');

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
  static const String routeName = '/developers';

  const DevelopersView({super.key});

  @override
  State<DevelopersView> createState() => _DevelopersViewState();
}

class _DevelopersViewState extends State<DevelopersView> {
  final BreezPreferences _preferences = const BreezPreferences();
  BugReportBehavior bugReportBehavior = BugReportBehavior.prompt;

  @override
  void initState() {
    super.initState();
    _preferences.getBugReportBehavior().then(
          (BugReportBehavior value) => bugReportBehavior = value,
          onError: (Object e) => _logger.warning(e),
        );
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const back_button.BackButton(),
        title: Text(texts.home_drawer_item_title_developers),
        actions: <Widget>[
          PopupMenuButton<Choice>(
            onSelected: (Choice c) => c.function(context),
            color: themeData.colorScheme.surface,
            icon: Icon(
              Icons.more_vert,
              color: themeData.iconTheme.color,
            ),
            itemBuilder: (BuildContext context) => <Choice>[
              Choice(
                title: texts.developers_page_menu_export_keys_title,
                icon: Icons.phone_android,
                function: _exportKeys,
              ),
              Choice(
                title: texts.developers_page_menu_share_logs_title,
                icon: Icons.share,
                function: (_) => shareLog(),
              ),
              Choice(
                title: texts.developers_page_menu_rescan_swaps_title,
                icon: Icons.radar,
                function: _rescanOnchainSwaps,
              ),
              if (bugReportBehavior != BugReportBehavior.prompt)
                Choice(
                  title: texts.developers_page_menu_prompt_bug_report_title,
                  icon: Icons.bug_report,
                  function: (_) {
                    _preferences.setBugReportBehavior(BugReportBehavior.prompt).then(
                          (void value) => setState(
                            () {
                              bugReportBehavior = BugReportBehavior.prompt;
                            },
                          ),
                          onError: (Object e) => _logger.warning(e),
                        );
                  },
                ),
            ]
                .map(
                  (Choice choice) => PopupMenuItem<Choice>(
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
      // TODO(erdemyerebasmaz): Liquid - Remove Absorb Pointer once execute_command API is implemented
      body: AbsorbPointer(
        child: CommandLineInterface(scaffoldKey: scaffoldKey),
      ),
    );
  }

  void _exportKeys(BuildContext context) async {
    final AccountCubit accountCubit = context.read<AccountCubit>();
    final AccountState accountState = accountCubit.state;

    final CredentialsManager credentialsManager = ServiceInjector().credentialsManager;
    final Directory appDir = await getApplicationDocumentsDirectory();
    final ZipFileEncoder encoder = ZipFileEncoder();
    final String zipFilePath = '${appDir.path}/l-breez-keys.zip';
    encoder.create(zipFilePath);
    final List<File> credentialFiles = await credentialsManager.exportCredentials();
    for (File credentialFile in credentialFiles) {
      final Uint8List bytes = await credentialFile.readAsBytes();
      encoder.addArchiveFile(
        ArchiveFile(basename(credentialFile.path), bytes.length, bytes),
      );
    }

    final AppConfig config = await AppConfig.instance();
    final String sdkDirPath = Directory(config.sdkConfig.workingDir).path;
    final String networkName = config.sdkConfig.network.name;
    final String fingerprint = accountState.walletInfo!.fingerprint;
    final String walletStoragePath = '$sdkDirPath/$networkName/$fingerprint';
    final String storageFilePath = '$walletStoragePath/storage.sql';
    final File storageFile = File(storageFilePath);
    encoder.addFile(storageFile);
    encoder.close();
    final XFile zipFile = XFile(zipFilePath);
    Share.shareXFiles(<XFile>[zipFile]);
  }

  Future<void> _rescanOnchainSwaps(BuildContext context) async {
    final BreezTranslations texts = getSystemAppLocalizations();
    final ChainSwapCubit chainSwapCubit = context.read<ChainSwapCubit>();

    try {
      return await chainSwapCubit.rescanOnchainSwaps();
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showFlushbar(context, title: extractExceptionMessage(error, texts));
    }
  }
}
