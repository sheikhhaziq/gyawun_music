import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../../../services/file_storage.dart';
import '../../../../../../services/library.dart';
import '../../../../../../services/settings_manager.dart';

part 'backup_storage_state.dart';

class BackupStorageCubit extends Cubit<BackupStorageState> {
  final Box _settingsBox = Hive.box('SETTINGS');
  final FileStorage _fileStorage = GetIt.I<FileStorage>();

  late final VoidCallback _listener;

  BackupStorageCubit()
      : super(
          BackupStorageState(
            appFolder: Hive.box('SETTINGS').get(
              'APP_FOLDER',
              defaultValue: GetIt.I<FileStorage>().storagePaths.basePath,
            ),
          ),
        ) {
    _listener = _emit;
    _settingsBox.listenable(keys: ['APP_FOLDER']).addListener(_listener);
  }

  void _emit() {
    if (isClosed) return;
    emit(
      state.copyWith(
        appFolder: _settingsBox.get(
          'APP_FOLDER',
          defaultValue: GetIt.I<FileStorage>().storagePaths.basePath,
        ),
        lastResult: null, // clear one-shot result
      ),
    );
  }

  Future<void> setAppFolder(String path) async {
    await _settingsBox.put('APP_FOLDER', path);
    await _fileStorage.updateDirectories();
  }

  Future<void> restore() async {
    final success = await _fileStorage.loadBackup();
    emit(
      state.copyWith(
        lastResult: success ? const RestoreSuccess() : const RestoreFailure(),
      ),
    );
  }

  Future<void> backup({
    required String action,
    required List items,
  }) async {
    final Map backup = {
      'name': 'Gyawun',
      'type': 'backup',
      'version': 1,
      'data': {},
    };

    if (items.contains('playlists')) {
      backup['data']['playlists'] = GetIt.I<LibraryService>().playlists;
    }

    if (items.contains('settings')) {
      final settings =
          Map<String, dynamic>.from(GetIt.I<SettingsManager>().settings);
      settings.remove('YTMUSIC_AUTH');
      backup['data']['settings'] = settings;
    }

    if (items.contains('favourites')) {
      backup['data']['favourites'] = Hive.box('FAVOURITES').toMap();
    }

    if (items.contains('song history')) {
      backup['data']['song_history'] = Hive.box('SONG_HISTORY').toMap();
    }

    if (items.contains('downloads')) {
      backup['data']['downloads'] = Hive.box('DOWNLOADS').toMap();
    }

    String? path;
    if (action == 'Save') {
      path = await _fileStorage.saveBackUp(backup);
    } else {
      path = await _fileStorage.shareBackUp(backup);
    }

    emit(
      state.copyWith(
        lastResult:
            (path.isEmpty) ? const BackupFailure() : BackupSuccess(path),
      ),
    );
  }

  @override
  Future<void> close() {
    _settingsBox.listenable(keys: ['APP_FOLDER']).removeListener(_listener);
    return super.close();
  }
}
