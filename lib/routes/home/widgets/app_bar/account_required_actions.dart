import 'package:flutter/material.dart';
import 'package:l_breez/bloc/account/account_bloc.dart';
import 'package:l_breez/bloc/account/account_state.dart';
import 'package:l_breez/bloc/account/credentials_manager.dart';
import 'package:l_breez/bloc/backup/backup_bloc.dart';
import 'package:l_breez/bloc/backup/backup_state.dart';
import 'package:l_breez/bloc/ext/block_builder_extensions.dart';
import 'package:l_breez/routes/home/widgets/app_bar/warning_action.dart';
import 'package:l_breez/routes/home/widgets/enable_backup_dialog.dart';
import 'package:l_breez/routes/home/widgets/rotator.dart';
import 'package:l_breez/services/injector.dart';
import 'package:l_breez/widgets/backup_in_progress_dialog.dart';
import 'package:logging/logging.dart';

final _log = Logger("AccountRequiredActionsIndicator");

class AccountRequiredActionsIndicator extends StatelessWidget {
  const AccountRequiredActionsIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return BlocBuilder2<AccountBloc, AccountState, BackupBloc, BackupState?>(
      builder: (context, accState, backupState) {
        _log.fine("Building with: accState: $accState backupState: $backupState");

        List<Widget> warnings = [];

        if (accState.verificationStatus == VerificationStatus.UNVERIFIED) {
          warnings.add(
            WarningAction(
              onTap: () async {
                await ServiceInjector().keychain.read(CredentialsManager.accountMnemonic).then(
                      (accountMnemonic) => Navigator.pushNamed(
                        context,
                        '/mnemonics',
                        arguments: accountMnemonic,
                      ),
                    );
              },
            ),
          );
        }

        if (backupState != null && backupState.status == BackupStatus.INPROGRESS) {
          warnings.add(
            WarningAction(
              onTap: () {
                showDialog(
                  useRootNavigator: false,
                  useSafeArea: false,
                  context: context,
                  builder: (_) => const BackupInProgressDialog(),
                );
              },
              iconWidget: Rotator(
                child: Image(
                  image: const AssetImage("src/icon/sync.png"),
                  color: themeData.appBarTheme.actionsIconTheme!.color!,
                ),
              ),
            ),
          );
        }

        if (backupState?.status == BackupStatus.FAILED) {
          warnings.add(
            WarningAction(
              onTap: () {
                showDialog(
                  useRootNavigator: false,
                  useSafeArea: false,
                  context: context,
                  builder: (_) => const EnableBackupDialog(),
                );
              },
            ),
          );
        }

        if (warnings.isEmpty) {}

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: warnings,
        );
      },
    );
  }
}
