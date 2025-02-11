import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/theme/src/breez_light_theme.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:service_injector/service_injector.dart';

class SecurityMnemonicsManagement extends StatefulWidget {
  const SecurityMnemonicsManagement({super.key});

  @override
  State<SecurityMnemonicsManagement> createState() => _SecurityMnemonicsManagementState();
}

class _SecurityMnemonicsManagementState extends State<SecurityMnemonicsManagement> {
  late Future<bool> _isVerificationCompleteFuture;

  @override
  void initState() {
    super.initState();
    _isVerificationCompleteFuture = MnemonicVerificationStatusPreferences.isVerificationComplete();
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return FutureBuilder<bool>(
      future: _isVerificationCompleteFuture,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (!snapshot.hasData) {
          return Container(color: breezLightTheme.canvasColor);
        }

        final bool isVerified = snapshot.data ?? false;

        return BlocBuilder<SecurityCubit, SecurityState>(
          builder: (BuildContext context, SecurityState securityState) {
            return ListTile(
              title: Text(
                isVerified
                    ? texts.mnemonics_confirmation_display_backup_phrase
                    : texts.mnemonics_confirmation_verify_backup_phrase,
                style: themeData.primaryTextTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
                maxLines: 1,
              ),
              trailing: const Icon(
                Icons.keyboard_arrow_right,
                color: Colors.white,
                size: 30.0,
              ),
              onTap: () async {
                // TODO(erdemyerebasmaz): Handle the case accountMnemonic is null as restoreMnemonic is now nullable
                await ServiceInjector().credentialsManager.restoreMnemonic().then(
                  (String? accountMnemonic) async {
                    if (context.mounted) {
                      if (!isVerified) {
                        Navigator.pushNamed(
                          context,
                          MnemonicsConfirmationPage.routeName,
                          arguments: accountMnemonic,
                        );
                      } else {
                        Navigator.push(
                          context,
                          FadeInRoute<void>(
                            builder: (BuildContext context) => MnemonicsPage(
                              mnemonics: accountMnemonic!,
                              viewMode: true,
                            ),
                          ),
                        );
                      }
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
