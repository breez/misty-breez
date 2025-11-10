import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/main/bootstrap_error_page.dart';
import 'package:misty_breez/routes/mnemonic_display/mnemonic_display_page.dart';
import 'package:service_injector/service_injector.dart';

export 'bootstrap.dart';
export 'bootstrap_error_page.dart';
export 'hydrated_bloc_storage.dart';

final Logger _logger = Logger('Bootstrap');

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      try {
        final String? mnemonic = await ServiceInjector().credentialsManager.restoreMnemonic();
        if (mnemonic != null) {
          runApp(MnemonicDisplayPage(mnemonic: mnemonic));
        } else {
          throw Exception('No credentials found in secure storage');
        }
      } catch (error, stackTrace) {
        runApp(BootstrapErrorPage(error: error, stackTrace: stackTrace));
      }
    },
    (Object error, StackTrace stackTrace) async {
      if (error is! FlutterErrorDetails) {
        _logger.severe('FlutterError: $error', error, stackTrace);
      }
    },
  );
}
