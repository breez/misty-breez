import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';

export 'backup_state.dart';

final Logger _logger = Logger('BackupCubit');

class BackupCubit extends Cubit<BackupState?> {
  final BreezSDKLiquid _breezSdkLiquid;

  BackupCubit(this._breezSdkLiquid) : super(null);

  // TODO(erdemyerebasmaz): Liquid - Listen to Backup events
  // ignore: unused_element
  void _listenBackupEvents() {
    // _breezSdkLiquid.backupStream.listen((event) {
    //   _logger.info('got state: $event');
    // });
  }

  /// Start the backup process
  Future<void> backup() async {
    try {
      emit(BackupState(status: BackupStatus.inProgress));
      _breezSdkLiquid.instance?.backup(req: const BackupRequest());
      emit(BackupState(status: BackupStatus.success));
    } catch (e) {
      _logger.info('Failed to backup');
      emit(BackupState(status: BackupStatus.failed));
    }
  }
}
