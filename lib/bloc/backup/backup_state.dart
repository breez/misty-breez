enum BackupStatus { failed, success, inProgress }

class BackupState {
  final BackupStatus status;

  BackupState({required this.status});

  @override
  String toString() {
    return 'BackupState{status: $status}';
  }
}
