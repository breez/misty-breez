import 'dart:io';

import 'package:keychain/keychain.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

final _log = Logger("CredentialsManager");

const String accountMnemonic = "account_mnemonic";
const String accountApiKey = "account_api_key";

class CredentialsManager {
  final KeyChain keyChain;

  CredentialsManager({required this.keyChain});

  Future storeMnemonic({
    required String mnemonic,
  }) async {
    try {
      await _storeMnemonic(mnemonic);
      _log.info("Stored credentials successfully");
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  Future<String?> restoreMnemonic() async {
    try {
      String? mnemonicStr = await keyChain.read(accountMnemonic);
      _log.info(
        (mnemonicStr != null)
            ? "Restored credentials successfully"
            : "No credentials found in secure storage",
      );
      return mnemonicStr;
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  Future deleteMnemonic() async {
    try {
      await keyChain.delete(accountMnemonic);
      _log.info("Deleted credentials successfully");
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  // Helper methods
  Future<void> _storeMnemonic(String mnemonic) async {
    await keyChain.write(accountMnemonic, mnemonic);
  }

  Future<List<File>> exportCredentials() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      var keysDir = tempDir.createTempSync("keys");
      final File mnemonicFile = await File('${keysDir.path}/phrase').create(recursive: true);
      String? mnemonic = await restoreMnemonic();
      if (mnemonic != null) {
        mnemonicFile.writeAsString(mnemonic);
      } else {
        throw Exception("No mnemonics");
      }
      return [mnemonicFile];
    } catch (e) {
      throw e.toString();
    }
  }
}
