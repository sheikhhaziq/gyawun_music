import 'dart:typed_data';

import 'package:extension_manager/extension_manager.dart';

class InMemoryStore implements InstalledExtensionStore {
  final records = <String, InstalledRecord>{};

  /// Set to make the next save fail, to test cleanup.
  Object? failOnSave;

  @override
  Future<List<InstalledRecord>> all() async => records.values.toList();

  @override
  Future<void> save(InstalledRecord record) async {
    final error = failOnSave;
    if (error != null) throw error;
    records[record.id] = record;
  }

  @override
  Future<void> delete(String id) async => records.remove(id);
}

class InMemoryFiles implements ArchiveFiles {
  final files = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String id) async => files[id];

  @override
  Future<void> write(String id, Uint8List bytes) async => files[id] = bytes;

  @override
  Future<void> delete(String id) async => files.remove(id);
}
