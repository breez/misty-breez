import 'package:breez_translations/breez_translations_locales.dart';
import 'package:credentials_manager/credentials_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/initial_walkthrough/mnemonics/mnemonics_page.dart';
import 'package:l_breez/widgets/route.dart';
import 'package:service_injector/service_injector.dart';

class SecurityMnemonicsManagement extends StatelessWidget {
  const SecurityMnemonicsManagement({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, account) {
        final isVerified = (account.verificationStatus == VerificationStatus.verified);

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
            await ServiceInjector().keychain.read(CredentialsManager.accountMnemonic).then(
              (accountMnemonic) {
                if (account.verificationStatus == VerificationStatus.unverified) {
                  Navigator.pushNamed(
                    context,
                    '/mnemonics',
                    arguments: accountMnemonic,
                  );
                } else {
                  Navigator.push(
                    context,
                    FadeInRoute(
                      builder: (context) => MnemonicsPage(
                        mnemonics: accountMnemonic!,
                        viewMode: true,
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
