import 'dart:io';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/security/change_pin_page.dart';
import 'package:l_breez/routes/security/widget/local_auth_switch.dart';
import 'package:l_breez/routes/security/widget/security_pin_interval.dart';
import 'package:l_breez/widgets/designsystem/switch/simple_switch.dart';
import 'package:l_breez/widgets/preview/preview.dart';
import 'package:l_breez/widgets/route.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class SecurityPinManagement extends StatelessWidget {
  const SecurityPinManagement({super.key});

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
    final themeData = Theme.of(context);
    final navigator = Navigator.of(context);
    final securityCubit = context.read<SecurityCubit>();

    return BlocBuilder<SecurityCubit, SecurityState>(
      builder: (context, state) {
        if (state.pinStatus == PinStatus.enabled) {
          return Column(
            children: [
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
                  FadeInRoute(
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
              FadeInRoute(
                builder: (_) => const ChangePinPage(),
              ),
            ),
          );
        }
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: Directory(
      join((await getApplicationDocumentsDirectory()).path, "preview_storage"),
    ),
  );
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<SecurityCubit>(
          create: (BuildContext context) => SecurityCubit(),
        ),
      ],
      child: const Preview(
        [
          SecurityPinManagement(),
        ],
      ),
    ),
  );
}
