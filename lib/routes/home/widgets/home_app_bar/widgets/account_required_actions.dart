import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';
import 'package:service_injector/service_injector.dart';

final Logger _logger = Logger('AccountRequiredActionsIndicator');

class AccountRequiredActionsIndicator extends StatefulWidget {
  const AccountRequiredActionsIndicator({super.key});

  @override
  State<AccountRequiredActionsIndicator> createState() => _AccountRequiredActionsIndicatorState();
}

class _AccountRequiredActionsIndicatorState extends State<AccountRequiredActionsIndicator> {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        final List<Widget> warnings = <Widget>[];

        final RefundState refundState = context.watch<RefundCubit>().state;
        if (refundState.hasRefundables) {
          _logger.info('Adding refundables warning.');
          warnings.add(const RefundablesWarningAction());
        }

        final SecurityState securityState = context.read<SecurityCubit>().state;
        if (securityState.verificationStatus != VerificationStatus.verified) {
          _logger.info('Adding mnemonic verification warning.');
          warnings.add(const VerifyMnemonicWarningAction());
        }

        final BackupState? backupState = context.watch<BackupCubit>().state;
        if (backupState != null && backupState.status == BackupStatus.inProgress) {
          _logger.info('Adding backup in progress warning.');
          warnings.add(const BackupInProgressWarningAction());
        }

        if (backupState?.status == BackupStatus.failed) {
          _logger.info('Adding backup error warning.');
          warnings.add(const BackupFailedWarningAction());
        }

        if (warnings.isEmpty) {
          return const SizedBox.shrink();
        }

        _logger.info('Total # of warnings: ${warnings.length}');

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: warnings,
        );
      },
    );
  }
}

class RefundablesWarningAction extends StatelessWidget {
  static final Logger _logger = Logger('RefundablesWarningAction');

  const RefundablesWarningAction({super.key});

  @override
  Widget build(BuildContext context) {
    return WarningAction(
      onTap: () {
        _logger.info('Redirecting user to refund page.');
        if (context.mounted) {
          Navigator.of(context).pushNamed(
            GetRefundPage.routeName,
          );
        }
      },
    );
  }
}

class VerifyMnemonicWarningAction extends StatelessWidget {
  static final Logger _logger = Logger('VerifyMnemonicWarningAction');

  const VerifyMnemonicWarningAction({super.key});

  @override
  Widget build(BuildContext context) {
    return WarningAction(
      onTap: () async {
        _logger.info('Redirecting user to mnemonics confirmation page.');
        final String? accountMnemonic = await ServiceInjector().credentialsManager.restoreMnemonic();
        if (context.mounted && accountMnemonic != null) {
          Navigator.pushNamed(
            context,
            MnemonicsConfirmationPage.routeName,
            arguments: accountMnemonic,
          );
        }
      },
    );
  }
}

class BackupInProgressWarningAction extends StatelessWidget {
  static final Logger _logger = Logger('BackupInProgressWarningAction');

  const BackupInProgressWarningAction({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return WarningAction(
      onTap: () {
        _logger.info('Display backup in progress dialog.');
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
    );
  }
}

class BackupFailedWarningAction extends StatelessWidget {
  static final Logger _logger = Logger('BackupFailedWarningAction');

  const BackupFailedWarningAction({super.key});

  @override
  Widget build(BuildContext context) {
    return WarningAction(
      onTap: () {
        _logger.info('Display enable backup dialog.');
        showDialog(
          useRootNavigator: false,
          useSafeArea: false,
          context: context,
          builder: (_) => const EnableBackupDialog(),
        );
      },
    );
  }
}
