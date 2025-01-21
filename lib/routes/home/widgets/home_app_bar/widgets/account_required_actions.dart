import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';
import 'package:service_injector/service_injector.dart';

final Logger _logger = Logger('AccountRequiredActionsIndicator');

class AccountRequiredActionsIndicator extends StatelessWidget {
  const AccountRequiredActionsIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final AccountCubit accountCubit = context.read<AccountCubit>();
    final AccountState accountState = accountCubit.state;
    final SecurityCubit securityCubit = context.read<SecurityCubit>();
    final SecurityState securityState = securityCubit.state;
    final BackupCubit backupCubit = context.read<BackupCubit>();
    final BackupState? backupState = backupCubit.state;
    final RefundCubit refundCubit = context.read<RefundCubit>();
    final RefundState refundState = refundCubit.state;

    final ThemeData themeData = Theme.of(context);

    _logger.fine(
      'Building with: securityState: $securityState backupState: $backupState accountState: $accountState, refundState: $refundState',
    );

    final List<Widget> warnings = <Widget>[];

    final bool hasRefundables = refundState.refundables?.isNotEmpty ?? false;

    if (hasRefundables) {
      _logger.info('Adding refundables warning.');
      warnings.add(
        WarningAction(
          onTap: () {
            if (context.mounted) {
              Navigator.of(context).pushNamed(
                GetRefundPage.routeName,
              );
            }
          },
        ),
      );
    }

    /*if (!accountState.didCompleteInitialSync) {
              _logger.info('Adding sync warning.');
              warnings.add(
                WarningAction(
                  onTap: () async {},
                  iconWidget: Rotator(
                    child: Image(
                      image: const AssetImage('assets/icons/sync.png'),
                      color: themeData.appBarTheme.actionsIconTheme?.color,
                    ),
                  ),
                ),
              );
            }*/

    if (securityState.verificationStatus == VerificationStatus.unverified) {
      _logger.info('Adding mnemonic verification warning.');
      warnings.add(
        WarningAction(
          onTap: () async {
            // TODO(erdemyerebasmaz): Handle the case accountMnemonic is null as restoreMnemonic is now nullable
            await ServiceInjector().credentialsManager.restoreMnemonic().then(
              (String? accountMnemonic) {
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
      _logger.info('Adding backup in progress warning.');
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
              image: const AssetImage('assets/icons/sync.png'),
              color: themeData.appBarTheme.actionsIconTheme!.color!,
            ),
          ),
        ),
      );
    }

    if (backupState?.status == BackupStatus.failed) {
      _logger.info('Adding backup error warning.');
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

    _logger.info('Total # of warnings: ${warnings.length}');
    if (warnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: warnings,
    );
  }
}
