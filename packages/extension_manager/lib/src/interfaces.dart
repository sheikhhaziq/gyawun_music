import 'dart:typed_data';

import 'installed_record.dart';

/// Where installed-extension records live (a database in the app).
abstract interface class InstalledExtensionStore {
  Future<List<InstalledRecord>> all();

  /// Inserts or replaces the record with the same id.
  Future<void> save(InstalledRecord record);

  /// Deleting an unknown id is not an error.
  Future<void> delete(String id);
}

/// Where archives are kept (the app's private directory).
///
/// Files are addressed by extension id, which the caller has already
/// validated. Implementations must never build paths from anything else.
abstract interface class ArchiveFiles {
  /// Null if there is no archive for [id].
  Future<Uint8List?> read(String id);

  /// Must be atomic: write a temporary file, then rename it over the target,
  /// so a crash never leaves a half-written archive.
  Future<void> write(String id, Uint8List bytes);

  /// Deleting an unknown id is not an error.
  Future<void> delete(String id);
}