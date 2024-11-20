import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/widgets/widgets.dart';

class SecurityPinManagement extends StatelessWidget {
  const SecurityPinManagement({super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);
    final NavigatorState navigator = Navigator.of(context);
    final SecurityCubit securityCubit = context.read<SecurityCubit>();

    return BlocBuilder<SecurityCubit, SecurityState>(
      builder: (BuildContext context, SecurityState state) {
        if (state.pinStatus == PinStatus.enabled) {
          return Column(
            children: <Widget>[
              SimpleSwitch(
                text: texts.security_and_backup_pin_option_deactivate,
                switchValue: true,
                onChanged: (_) => securityCubit.clearPin(),
              ),
              const Divider(),
              SecurityPinInterval(interval: state.lockInterval),
              const Divider(),
              ListTile(
                title: Text(
                  texts.security_and_backup_change_pin,
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
                onTap: () => navigator.push(
                  FadeInRoute<void>(
                    builder: (_) => const ChangePinPage(),
                  ),
                ),
              ),
              const Divider(),
              const LocalAuthSwitch(),
            ],
          );
        } else {
          return ListTile(
            title: Text(
              texts.security_and_backup_pin_option_create,
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
            onTap: () => navigator.push(
              FadeInRoute<void>(
                builder: (_) => const ChangePinPage(),
              ),
            ),
          );
        }
      },
    );
  }
}
