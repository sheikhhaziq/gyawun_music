import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as path;
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
    return _save('Music', fileName, bytes);
  }

  Future<String?> saveBackup(String fileName, List<int> bytes) {
    return _save('Backups', fileName, bytes);
  }

  /// Deletes a previously saved file.
  /// [relativePath] must be the same path returned by saveMusic/saveBackup.
  Future<bool> deleteFile(String relativePath) async {
    return _deleteViaSaf(relativePath);
  }

  /// Checks whether a previously saved file exists.
  /// [relativePath] must be the same path returned by saveMusic/saveBackup.
  Future<bool> fileExists(String relativePath) async {
    try {
      final String? treeUri = _settingsBox.get(_appFolderKey);
      if (treeUri == null) return false;
      SafDocumentFile? current = await _safUtil.documentFileFromUri(
        path.join(treeUri, relativePath),
        false,
      );

      if (current == null) return false;

      final parts = relativePath.split('/');

      for (final name in parts) {
        final List<SafDocumentFile> children = await _safUtil.list(
          current!.uri,
        );

        final SafDocumentFile? next = children.firstWhereOrNull(
          (f) => f.name == name,
        );
        print(next?.uri.toString());

        if (next == null) {
          return false; // segment not found
        }

        current = next;
      }

      // Successfully resolved full path
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List?>? pickFile() async {
    final file = await _safUtil.pickFile(mimeTypes: ['application/json']);
    if (file == null) return null;
    final data = await _safStream.readFileBytes(file.uri);
    return data;
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

  Future<bool> ensureDirectoryPermission() async {
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

    return stored;
  }

  /* ------------------------------------------------------------ */
  /* Internal routing                                             */
  /* ------------------------------------------------------------ */

  /* ------------------------------------------------------------ */
  /* SAF (Android 10+)                                            */
  /* ------------------------------------------------------------ */

  Future<String?> _save(String subDir, String fileName, List<int> bytes) async {
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
}
