import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/initial_walkthrough/mnemonics/mnemonics_confirmation_page.dart';
import 'package:l_breez/routes/initial_walkthrough/mnemonics/mnemonics_page.dart';
import 'package:l_breez/widgets/route.dart';
import 'package:service_injector/service_injector.dart';

class SecurityMnemonicsManagement extends StatelessWidget {
  const SecurityMnemonicsManagement({super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return BlocBuilder<SecurityCubit, SecurityState>(
      builder: (BuildContext context, SecurityState securityState) {
        final bool isVerified = (securityState.verificationStatus == VerificationStatus.verified);

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
              (String? accountMnemonic) {
                if (context.mounted) {
                  if (securityState.verificationStatus == VerificationStatus.unverified) {
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
  }
}
