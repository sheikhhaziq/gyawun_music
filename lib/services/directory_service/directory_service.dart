import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart';

class DirectoryService {
  final SafStream _safStream;
  final SafUtil _safUtil;
  final Box _settingsBox = Hive.box('SETTINGS');

  static const _appFolderKey = 'APP_FOLDER';

  DirectoryService({required SafStream safStream, required SafUtil safUtil})
    : _safStream = safStream,
      _safUtil = safUtil;

  /* ------------------------------------------------------------ */
  /* Public API                                                   */
  /* ------------------------------------------------------------ */

  Future<String?> saveMusic(String fileName, List<int> bytes) {
    return _save(subDir: 'Music', fileName: fileName, bytes: bytes);
  }

  Future<String?> saveBackup(String fileName, List<int> bytes) {
    return _save(subDir: 'Backups', fileName: fileName, bytes: bytes);
  }

  /// Deletes a previously saved file.
  /// [relativePath] must be the same path returned by saveMusic/saveBackup.
  Future<bool> deleteFile(String relativePath) async {
    if (await _shouldUseSaf()) {
      return _deleteViaSaf(relativePath);
    } else {
      return _deleteLegacy(relativePath);
    }
  }

  Future<bool> _deleteViaSaf(String relativePath) async {
    try {
      final String? treeUri = _settingsBox.get(_appFolderKey);
      if (treeUri == null) return false;

      // Resolve root directory
      SafDocumentFile? current = await _safUtil.documentFileFromUri(
        treeUri,
        true,
      );

      if (current == null) return false;

      final parts = relativePath.split('/');

      for (int i = 0; i < parts.length; i++) {
        final String name = parts[i];

        // List children of current directory
        final List<SafDocumentFile> children = await _safUtil.list(
          current!.uri,
        );

        // Find matching child by name
        final SafDocumentFile? next = children.firstWhereOrNull(
          (f) => f.name == name,
        );

        if (next == null) {
          return false; // path does not exist
        }

        // Last segment → delete
        if (i == parts.length - 1) {
          await _safUtil.delete(next.uri, false);
          return true;
        }

        // Otherwise continue walking
        current = next;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _deleteLegacy(String relativePath) async {
    try {
      const base = '/storage/emulated/0';

      final file = File('$base/$relativePath');
      if (!await file.exists()) return false;

      await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Ensures SAF directory permission exists.
  /// If already granted, does nothing.
  /// Returns true if permission is available after the call.
  Future<bool> ensureDirectoryPermission() async {
    if (!await _shouldUseSaf()) {
      // Legacy storage does not need SAF
      return true;
    }

    // Check if we already have a persisted SAF directory
    final existing = _settingsBox.get(_appFolderKey);
    if (existing != null && existing is String && existing.isNotEmpty) {
      return true; // ✅ already granted
    }

    // Request directory from user
    final dir = await _safUtil.pickDirectory(
      writePermission: true,
      persistablePermission: true,
    );

    if (dir == null) {
      return false; // ❌ user cancelled
    }

    // Save SAF tree URI
    await _settingsBox.put(_appFolderKey, dir.uri);
    return true;
  }

  /// 📂 User selects directory (SAF picker)
  Future<String?> changeDirectory() async {
    if (!await _shouldUseSaf()) {
      const legacy = '/storage/emulated/0/Gyawun Music';
      _settingsBox.put(_appFolderKey, legacy);
      return legacy;
    }

    final dir = await _safUtil.pickDirectory(
      writePermission: true,
      persistablePermission: true,
    );

    if (dir == null) {
      return null;
    }

    // ✅ Save SAF tree URI
    await _settingsBox.put(_appFolderKey, dir.uri);

    return dir.uri;
  }

  /// UI-friendly current location
  Future<String> get currentLocation async {
    final stored = _settingsBox.get(_appFolderKey);

    if (stored == null) {
      return 'Not configured';
    }

    if (!await _shouldUseSaf()) {
      return stored;
    }

    return 'Selected folder';
  }

  /* ------------------------------------------------------------ */
  /* Internal routing                                             */
  /* ------------------------------------------------------------ */

  Future<String?> _save({
    required String subDir,
    required String fileName,
    required List<int> bytes,
  }) async {
    if (await _shouldUseSaf()) {
      return _saveViaSaf(subDir, fileName, bytes);
    } else {
      return _saveLegacy(subDir, fileName, bytes);
    }
  }

  /* ------------------------------------------------------------ */
  /* SAF (Android 10+)                                            */
  /* ------------------------------------------------------------ */

  Future<String?> _saveViaSaf(
    String subDir,
    String fileName,
    List<int> bytes,
  ) async {
    try {
      final String? treeUri = _settingsBox.get(_appFolderKey);
      if (treeUri == null) return null;

      // 1. Ensure directories exist:
      //    Gyawun Music / <subDir>
      final targetDir = await _safUtil.mkdirp(treeUri, [
        'Gyawun Music',
        subDir,
      ]);

      // 2. Write file INTO that directory (filename only)
      await _safStream.writeFileBytes(
        targetDir.uri,
        fileName,
        'application/octet-stream',
        Uint8List.fromList(bytes),
        overwrite: true,
      );

      // 3. Return logical path for UI
      return 'Gyawun Music/$subDir/$fileName';
    } catch (e) {
      return null;
    }
  }

  /* ------------------------------------------------------------ */
  /* Legacy (Android ≤ 9)                                         */
  /* ------------------------------------------------------------ */

  Future<String?> _saveLegacy(
    String subDir,
    String fileName,
    List<int> bytes,
  ) async {
    try {
      final granted = await Permission.storage.request().isGranted;
      if (!granted) return null;

      const base = '/storage/emulated/0/Gyawun Music';

      final dir = Directory('$base/$subDir');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      return file.path;
    } catch (_) {
      return null;
    }
  }

  /* ------------------------------------------------------------ */
  /* Platform logic                                               */
  /* ------------------------------------------------------------ */

  Future<bool> _shouldUseSaf() async {
    if (!Platform.isAndroid) return false;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt >= 29;
  }
}
