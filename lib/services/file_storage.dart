import 'dart:convert';
import 'dart:io';
import 'package:audiotags/audiotags.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/services/download_manager.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

import '../utils/enhanced_image.dart';
import 'history_manager.dart';
import 'library.dart';
import 'settings_manager.dart';
import 'favourites_manager.dart';

class FileStorage {
  static final String defaultPath = '/storage/emulated/0/Download/';
  late StoragePaths _storagePaths;
  FileStorage._();

  static Future<FileStorage> create() async {
    final instance = FileStorage._();
    await instance.setupPaths();
    return instance;
  }

  Future<void> setupPaths() async {
    Directory directory = await _getAppDirectory();
    _storagePaths = StoragePaths(
      basePath: directory.path,
      backupPath: path.join(directory.path, 'Back Up'),
      musicPath: path.join(directory.path, 'Music'),
    );
    await _getDirectory(_storagePaths.backupPath);
    await _getDirectory(_storagePaths.musicPath);
  }

  Future<String> saveBackUp(Map data) async {
    String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    String fileName = '${timestamp}_backup';
    if (!(await requestPermissions())) return "";
    Directory directory = await _getDirectory(_storagePaths.backupPath);

    String filePath = path.join(directory.path, '$fileName.json');
    File file = File(filePath);
    try {
      if (await file.exists()) {
        await file.delete();
      }
      File result = await file.writeAsString(jsonEncode(data), flush: true);
      return result.path;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> shareBackUp(Map data) async {
    String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    String fileName = '${timestamp}_backup.json';
    try {
      final params = ShareParams(
        files: [
          XFile.fromData(utf8.encode(jsonEncode(data)), mimeType: 'text/plain'),
        ],
        fileNameOverrides: [fileName],
      );
      ShareResult result = await SharePlus.instance.share(params);
      return result.raw;
    } catch (e) {
      rethrow;
    }
  }

  Future<File?> saveMusic(List<int> data, Map song, {extension = 'm4a'}) async {
    String fileName = song['title'];
    final RegExp avoid = RegExp(r'[\.\\\*\:\(\)\"\?#/;\|]');
    fileName = fileName.replaceAll(avoid, '').replaceAll("'", '');
    //fileName = Uri.decodeFull(fileName);
    if (!(await requestPermissions())) return null;
    Directory directory = await _getDirectory(_storagePaths.musicPath);

    File file = File(path.join(directory.path, '$fileName.$extension'));
    int number = 1;
    while (file.existsSync()) {
      file = File((path.join(directory.path, '$fileName($number).$extension')));
      number++;
    }
    try {
      if (await file.exists()) {
        await file.delete();
      }
      await file.writeAsBytes(data, flush: true);

      try {
        Response res = await get(
          Uri.parse(getEnhancedImage(song['thumbnails'].first['url'])),
        );
        Tag tag = Tag(
          title: song['title'],
          trackArtist: song['artists']
              ?.map((artist) => artist['name'])
              .join(','),
          album: song['album']?['name'],
          pictures: [
            Picture(bytes: res.bodyBytes, pictureType: PictureType.coverFront),
          ],
        );
        await AudioTags.write(file.path, tag);
      } catch (e) {
        await file.writeAsBytes(data, flush: true);
      }
      return file;
    } catch (e) {
      return null;
    }
  }

  Future<bool> loadBackup() async {
    if (!(await requestPermissions())) return false;
    FilePickerResult? picker = await FilePicker.platform.pickFiles(
      initialDirectory: _storagePaths.backupPath,
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picker == null) return false;
    final file = picker.files[0].xFile;
    String data = await file.readAsString();
    Map backup = jsonDecode(data);
    if (backup['name'] != 'Gyawun' && backup['type'] != 'backup') {
      return false;
    }
    Map? settings = backup['data']?['settings'];
    Map? favourites = backup['data']?['favourites'];
    Map? playlists = backup['data']?['playlists'];
    Map? history = backup['data']?['song_history'];
    Map? downloads = backup['data']?['downloads'];
    if (settings != null) {
      await GetIt.I<SettingsManager>().setSettings(settings);
      // await GetIt.I<YTMusic>().refreshHeaders();
    }
    if (favourites != null) {
      await GetIt.I<FavouritesManager>().setFavourites(favourites);
    }
    if (playlists != null) {
      await GetIt.I<LibraryService>().setPlaylists(playlists);
    }
    if (history != null) {
      await GetIt.I<HistoryManager>().songs.setHistory(history);
    }
    if (downloads != null) {
      await GetIt.I<DownloadManager>().setDownloads(downloads);
    }
    return true;
  }

  Future<Directory> _getAppDirectory() async {
    if (Platform.isAndroid) {
      return Directory(
        path.join(GetIt.I<SettingsManager>().appFolder, 'Gyawun'),
      );
    }
    if (Platform.isWindows) {
      return Directory(
        path.join((await getDownloadsDirectory())!.path, 'Gyawun'),
      );
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<Directory> _getDirectory(String pathString) async {
    Directory dir = Directory(pathString);
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<bool> requestPermissions() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Desktop platforms do not need permission
      return true;
    }

    if (Platform.isIOS) {
      // iOS app-specific storage doesn't require permission
      return true;
    }

    bool isGranted = false;

    if (Platform.isAndroid) {
      int sdkInt = (await _getAndroidSdkInt()) ?? 30;

      if (sdkInt >= 30) {
        // Android 11+ requires MANAGE_EXTERNAL_STORAGE for arbitrary access
        isGranted = await Permission.manageExternalStorage.isGranted;
        if (!isGranted) {
          await Permission.manageExternalStorage.request();
          isGranted = await Permission.manageExternalStorage.isGranted;
        }
      } else {
        // Android < 11 uses standard storage permission
        isGranted = await Permission.storage.isGranted;
        if (!isGranted) {
          await Permission.storage.request();
          isGranted = await Permission.storage.isGranted;
        }
      }

      if (!isGranted) {
        // Open settings if permission denied
        await openAppSettings();
      }
    }

    return isGranted;
  }

  // Helper function to get Android SDK version
  Future<int?> _getAndroidSdkInt() async {
    try {
      final String? sdkString = await MethodChannel(
        'flutter/platform',
      ).invokeMethod<String>('SystemNavigator.getPlatformVersion');
      if (sdkString != null) {
        final match = RegExp(r'Android (\d+)').firstMatch(sdkString);
        if (match != null) return int.tryParse(match.group(1)!);
      }
    } catch (_) {}
    return null;
  }
}

class StoragePaths {
  String basePath;
  String backupPath;
  String musicPath;
  StoragePaths({
    required this.basePath,
    required this.backupPath,
    required this.musicPath,
  });
}
