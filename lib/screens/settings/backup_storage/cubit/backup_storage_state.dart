part of 'backup_storage_cubit.dart';

@immutable
class BackupStorageState {
  final String appFolder;
  final String defaultPath;

  /// one-shot results
  final BackupResult? lastResult;

  const BackupStorageState({
    required this.appFolder,
    required this.defaultPath,
    this.lastResult,
  });

  BackupStorageState copyWith({
    String? appFolder,
    String? defaultPath,
    BackupResult? lastResult,
  }) {
    return BackupStorageState(
      appFolder: appFolder ?? this.appFolder,
      defaultPath: defaultPath ?? this.defaultPath,
      lastResult: lastResult,
    );
  }
}

sealed class BackupResult {
  const BackupResult();
}

class BackupSuccess extends BackupResult {
  final String path;
  const BackupSuccess(this.path);
}

class BackupFailure extends BackupResult {
  const BackupFailure();
}

class RestoreSuccess extends BackupResult {
  const RestoreSuccess();
}

class RestoreFailure extends BackupResult {
  const RestoreFailure();
}
