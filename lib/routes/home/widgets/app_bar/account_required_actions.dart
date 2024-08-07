import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/home/widgets/app_bar/warning_action.dart';
import 'package:l_breez/routes/home/widgets/enable_backup_dialog.dart';
import 'package:l_breez/routes/home/widgets/rotator.dart';
import 'package:l_breez/routes/initial_walkthrough/mnemonics/mnemonics_confirmation_page.dart';
import 'package:l_breez/widgets/backup_in_progress_dialog.dart';
import 'package:logging/logging.dart';
import 'package:service_injector/service_injector.dart';

final _log = Logger("AccountRequiredActionsIndicator");

class AccountRequiredActionsIndicator extends StatelessWidget {
  const AccountRequiredActionsIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return BlocBuilder<SecurityCubit, SecurityState>(
      builder: (context, securityState) {
        return BlocBuilder<BackupCubit, BackupState?>(
          builder: (context, backupState) {
            _log.fine("Building with: securityState: $securityState backupState: $backupState");

            List<Widget> warnings = [];

            if (securityState.verificationStatus == VerificationStatus.unverified) {
              warnings.add(
                WarningAction(
                  onTap: () async {
                    // TODO - Handle the case accountMnemonic is null as restoreMnemonic is now nullable
                    await ServiceInjector().credentialsManager.restoreMnemonic().then(
                      (accountMnemonic) {
                        if (context.mounted) {
                          return Navigator.pushNamed(
                            context,
                            MnemonicsConfirmationPage.routeName,
                            arguments: accountMnemonic,
                          );
                        }
                      },
                    );
                  },
                ),
              );
            }

            if (backupState != null && backupState.status == BackupStatus.inProgress) {
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

            if (backupState?.status == BackupStatus.failed) {
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
      },
    );
  }
}
