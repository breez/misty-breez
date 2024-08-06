library backup_cubit;

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/cubit/backup/backup_state.dart';
import 'package:logging/logging.dart';

export 'backup_state.dart';

final _log = Logger("BackupCubit");

class BackupCubit extends Cubit<BackupState?> {
  final BreezSDKLiquid _liquidSDK;

  BackupCubit(this._liquidSDK) : super(null);

  // TODO: Liquid - Listen to Backup events
  // ignore: unused_element
  _listenBackupEvents() {
    // _liquidSDK.backupStream.listen((event) {
    //   _log.info('got state: $event');
    // });
  }

  /// Start the backup process
  Future<void> backup() async {
    try {
      emit(BackupState(status: BackupStatus.inProgress));
      _liquidSDK.instance?.backup(req: const BackupRequest());
      emit(BackupState(status: BackupStatus.success));
    } catch (e) {
      _log.info("Failed to backup");
      emit(BackupState(status: BackupStatus.failed));
    }
  }
}
