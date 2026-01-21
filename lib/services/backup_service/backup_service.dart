import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:gyawun/services/directory_service/directory_service.dart';
import 'package:gyawun/services/library.dart';
import 'package:gyawun/services/settings_manager.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  final DirectoryService _directoryService;
  final SettingsManager _settingsManager;
  final LibraryService _libraryService;

  BackupService(
    DirectoryService directoryService,
    SettingsManager settingsManager,
    LibraryService libraryService,
  ) : _libraryService = libraryService,
      _directoryService = directoryService,
      _settingsManager = settingsManager;

  Future<String> get currentLocation async {
    return await _directoryService.currentLocation;
  }

  Future<String?> changeDirectory() async {
    return await _directoryService.changeDirectory();
  }

  /* ------------------------------------------------------------ */
  /* Restore                                                      */
  /* ------------------------------------------------------------ */

  Future<bool> loadBackup() async {
    final picker = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picker == null) return false;

    final file = picker.files.first.xFile;
    final data = await file.readAsString();

    final Map<String, dynamic> backup =
        jsonDecode(data) as Map<String, dynamic>;

    // ✅ Correct validation
    if (backup['name'] != 'Gyawun' || backup['type'] != 'backup') {
      return false;
    }

    final Map<String, dynamic>? payload =
        backup['data'] as Map<String, dynamic>?;

    if (payload == null) return false;

    final settings = payload['settings'];
    final favourites = payload['favourites'];
    final playlists = payload['playlists'];
    final history = payload['song_history'];
    final downloads = payload['downloads'];

    if (settings is Map<String, dynamic>) {
      await _settingsManager.setSettings(settings);
    }

    if (favourites is Map) {
      final box = Hive.box('FAVOURITES');
      for (final entry in favourites.entries) {
        box.put(entry.key, entry.value);
      }
    }

    if (playlists is Map<String, dynamic>) {
      await _libraryService.setPlaylists(playlists);
    }

    if (history is Map) {
      final box = Hive.box('SONG_HISTORY');
      for (final entry in history.entries) {
        box.put(entry.key, entry.value);
      }
    }

    if (downloads is Map) {
      final box = Hive.box('DOWNLOADS');
      for (final entry in downloads.entries) {
        box.put(entry.key, entry.value);
      }
    }

    return true;
  }

  /* ------------------------------------------------------------ */
  /* Save                                                        */
  /* ------------------------------------------------------------ */

  Future<String> saveBackUp(Map<String, dynamic> data) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '${timestamp}_backup.json';

    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);

    await _directoryService.saveBackup(fileName, bytes);
    return fileName;
  }

  /* ------------------------------------------------------------ */
  /* Share                                                       */
  /* ------------------------------------------------------------ */

  Future<String> shareBackUp(Map<String, dynamic> data) async {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '${timestamp}_backup.json';

    final params = ShareParams(
      files: [
        XFile.fromData(
          utf8.encode(jsonEncode(data)),
          mimeType: 'application/json',
        ),
      ],
      fileNameOverrides: [fileName],
    );

    final result = await SharePlus.instance.share(params);
    return result.raw;
  }
}
