enum BackupStatus { FAILED, SUCCESS, INPROGRESS }

class BackupState {
  final BackupStatus status;

  BackupState({required this.status});

  @override
  String toString() {
    return 'BackupState{status: $status}';
  }
}
