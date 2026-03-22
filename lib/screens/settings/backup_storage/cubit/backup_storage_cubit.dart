import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../services/file_storage.dart';
import '../../../../../../services/library.dart';
import '../../../../../../services/settings_manager.dart';
import '../../../../../../services/favourites_manager.dart';
import '../../../../services/download_manager.dart';
import '../../../../services/history_manager.dart';

part 'backup_storage_state.dart';

class BackupStorageCubit extends Cubit<BackupStorageState> {
  final SettingsManager _settingsManager = GetIt.I<SettingsManager>();
  final FileStorage _fileStorage = GetIt.I<FileStorage>();

  late final VoidCallback _listener;

  BackupStorageCubit()
    : super(
        BackupStorageState(
          appFolder: GetIt.I<SettingsManager>().appFolder,
          defaultPath: FileStorage.defaultPath,
        ),
      ) {
    _listener = _emit;
    _settingsManager.addListener(_listener);
  }

  void _emit() {
    if (isClosed) return;
    emit(
      state.copyWith(
        appFolder: _settingsManager.appFolder,
        lastResult: null, // clear one-shot result
      ),
    );
  }

  Future<void> setAppFolder(String path) async {
    _settingsManager.appFolder = path;
    await _fileStorage.setupPaths();
  }

  Future<void> restore() async {
    final success = await _fileStorage.loadBackup();
    emit(
      state.copyWith(
        lastResult: success ? const RestoreSuccess() : const RestoreFailure(),
      ),
    );
  }

  Future<void> backup({required String action, required List items}) async {
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
      final settings = Map<String, dynamic>.from(
        GetIt.I<SettingsManager>().settings,
      );
      settings.remove('YTMUSIC_AUTH');
      backup['data']['settings'] = settings;
    }

    if (items.contains('favourites')) {
      Map favourites = GetIt.I<FavouritesManager>().songs;
      backup['data']['favourites'] = favourites;
    }

    if (items.contains('song history')) {
      Map history = GetIt.I<HistoryManager>().songs.all;
      backup['data']['song_history'] = history;
    }

    if (items.contains('downloads')) {
      Map downloads = GetIt.I<DownloadManager>().downloads;
      backup['data']['downloads'] = downloads;
    }

    String? path;
    if (action == 'Save') {
      path = await _fileStorage.saveBackUp(backup);
    } else {
      path = await _fileStorage.shareBackUp(backup);
    }

    emit(
      state.copyWith(
        lastResult: (path.isEmpty)
            ? const BackupFailure()
            : BackupSuccess(path),
      ),
    );
  }

  @override
  Future<void> close() {
    _settingsManager.removeListener(_listener);
    return super.close();
  }
}
