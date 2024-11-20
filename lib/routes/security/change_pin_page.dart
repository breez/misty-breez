import 'dart:io';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:nested/nested.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:service_injector/service_injector.dart';

class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key});

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage> {
  String _firstPinCode = '';

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return Scaffold(
      appBar: AppBar(
        key: GlobalKey<ScaffoldState>(),
        leading: const back_button.BackButton(),
      ),
      body: PinCodeWidget(
        label: _moment() == _Moment.firstTime
            ? texts.security_and_backup_new_pin
            : texts.security_and_backup_new_pin_second_time,
        testPinCodeFunction: (String pin) async {
          if (_moment() == _Moment.firstTime) {
            setState(() {
              _firstPinCode = pin;
            });
            return const TestPinResult(true, clearOnSuccess: true);
          } else {
            if (pin == _firstPinCode) {
              final SecurityCubit securityCubit = context.read<SecurityCubit>();
              await securityCubit.setPin(pin);
              if (context.mounted) {
                Navigator.pop(context);
              }
              return const TestPinResult(true);
            } else {
              setState(() {
                _firstPinCode = '';
              });
              return TestPinResult(false, errorMessage: texts.security_and_backup_new_pin_do_not_match);
            }
          }
        },
      ),
    );
  }

  _Moment _moment() => _firstPinCode.isEmpty ? _Moment.firstTime : _Moment.confirmingPin;
}

enum _Moment {
  firstTime,
  confirmingPin,
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ServiceInjector injector = ServiceInjector();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: Directory(
      join((await getApplicationDocumentsDirectory()).path, 'preview_storage'),
    ),
  );
  runApp(
    MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<SecurityCubit>(
          create: (BuildContext context) => SecurityCubit(injector.keychain),
        ),
      ],
      child: MaterialApp(
        theme: breezLightTheme,
        home: const ChangePinPage(),
      ),
    ),
  );
}
