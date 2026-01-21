import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/backup_service/backup_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../../../services/library.dart';
import '../../../../../../services/settings_manager.dart';

part 'backup_storage_state.dart';

class BackupStorageCubit extends Cubit<BackupStorageState> {
  final BackupService _backupService;

  BackupStorageCubit(this._backupService)
    : super(const BackupStorageState(appFolder: 'Loading…')) {
    _loadCurrentLocation();
  }

  /* ------------------------------------------------------------ */
  /* Location                                                     */
  /* ------------------------------------------------------------ */

  Future<void> _loadCurrentLocation() async {
    final location = await _backupService.currentLocation;
    if (isClosed) return;

    emit(state.copyWith(appFolder: location));
  }

  /* ------------------------------------------------------------ */
  /* Restore                                                      */
  /* ------------------------------------------------------------ */

  Future<void> restore() async {
    final success = await _backupService.loadBackup();

    emit(
      state.copyWith(
        lastResult: success ? const RestoreSuccess() : const RestoreFailure(),
      ),
    );

    // Reload location in case restore affected storage
    await _loadCurrentLocation();
  }

  Future<void> changeDirectory() async {
    await _backupService.changeDirectory();
    await _loadCurrentLocation();
  }

  /* ------------------------------------------------------------ */
  /* Backup                                                       */
  /* ------------------------------------------------------------ */

  Future<void> backup({required String action, required List items}) async {
    final Map<String, dynamic> backup = {
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
      backup['data']['favourites'] = Hive.box('FAVOURITES').toMap();
    }

    if (items.contains('song history')) {
      backup['data']['song_history'] = Hive.box('SONG_HISTORY').toMap();
    }

    if (items.contains('downloads')) {
      backup['data']['downloads'] = Hive.box('DOWNLOADS').toMap();
    }

    String? result;
    if (action == 'Save') {
      result = await _backupService.saveBackUp(backup);
    } else {
      result = await _backupService.shareBackUp(backup);
    }

    emit(
      state.copyWith(
        lastResult: (result.isEmpty)
            ? const BackupFailure()
            : BackupSuccess(result),
      ),
    );

    // Reload location after backup (folder might change via SAF)
    await _loadCurrentLocation();
  }
}
