import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:l_breez/bloc/account/breez_liquid_sdk.dart';
import 'package:l_breez/bloc/backup/backup_state.dart';
import 'package:logging/logging.dart';

class BackupBloc extends Cubit<BackupState?> {
  final _log = Logger("BackupBloc");
  final BreezLiquidSDK _liquidSDK;

  BackupBloc(this._liquidSDK) : super(null);

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
      emit(BackupState(status: BackupStatus.INPROGRESS));
      _liquidSDK.instance?.backup(req: const BackupRequest());
      emit(BackupState(status: BackupStatus.SUCCESS));
    } catch (e) {
      _log.info("Failed to backup");
      emit(BackupState(status: BackupStatus.FAILED));
    }
  }
}
