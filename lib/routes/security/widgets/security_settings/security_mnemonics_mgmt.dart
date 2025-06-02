import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/widgets/route.dart';
import 'package:service_injector/service_injector.dart';

final Logger _logger = Logger('SecurityMnemonicsManagement');

/// Widget for managing mnemonic backup phrase verification and display
class SecurityMnemonicsManagement extends StatefulWidget {
  /// Creates a security mnemonics management widget
  const SecurityMnemonicsManagement({super.key});

  @override
  State<SecurityMnemonicsManagement> createState() => _SecurityMnemonicsManagementState();
}

class _SecurityMnemonicsManagementState extends State<SecurityMnemonicsManagement> {
  /// Future that resolves to whether mnemonic verification is complete
  late Future<bool> _isVerificationCompleteFuture;

  @override
  void initState() {
    super.initState();
    _isVerificationCompleteFuture = MnemonicVerificationStatusPreferences.isVerificationComplete();
    _logger.fine('Initialized mnemonics management');
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return FutureBuilder<bool>(
      future: _isVerificationCompleteFuture,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (!snapshot.hasData) {
          _logger.fine('Waiting for verification status data');
          return Container(color: breezLightTheme.canvasColor);
        }

        final bool isVerified = snapshot.data ?? false;
        _logger.fine('Mnemonic verification status: ${isVerified ? 'verified' : 'not verified'}');

        return BlocBuilder<SecurityCubit, SecurityState>(
          builder: (BuildContext context, SecurityState securityState) {
            return ListTile(
              title: Text(
                isVerified
                    ? texts.mnemonics_confirmation_display_backup_phrase
                    : texts.mnemonics_confirmation_verify_backup_phrase,
                style: themeData.primaryTextTheme.titleMedium?.copyWith(color: Colors.white),
                maxLines: 1,
              ),
              trailing: const Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0),
              onTap: () => _handleMnemonicsTap(context, isVerified),
            );
          },
        );
      },
    );
  }

  /// Handles tap on the mnemonics tile
  Future<void> _handleMnemonicsTap(BuildContext context, bool isVerified) async {
    _logger.info('Handling mnemonics tap, verified: $isVerified');

    try {
      final String? accountMnemonic = await ServiceInjector().credentialsManager.restoreMnemonic();

      if (!context.mounted || accountMnemonic == null) {
        _logger.warning('Context no longer mounted or mnemonic is null');
        return;
      }

      if (!isVerified) {
        _logger.info('Navigating to mnemonic confirmation page');
        Navigator.pushNamed(context, MnemonicsConfirmationPage.routeName, arguments: accountMnemonic);
      } else {
        _logger.info('Navigating to mnemonics view page');
        Navigator.push(
          context,
          FadeInRoute<void>(
            builder: (BuildContext context) => MnemonicsPage(mnemonics: accountMnemonic, viewMode: true),
          ),
        );
      }
    } catch (e) {
      _logger.severe('Error restoring mnemonic: $e');
      // Could show an error dialog here
    }
  }
}
