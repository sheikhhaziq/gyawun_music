import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:gmx/gmx.dart';

/// Builds a valid archive in memory and reads it back through the real
/// [GmxArchive.read], so tests exercise the same path as a real install.
GmxArchive buildArchive(
  String script, {
  Map<String, Object?> permissions = const {},
  String id = 'com.example.test',
}) {
  final metadata = jsonEncode({
    'id': id,
    'name': 'Test',
    'version': '1.0.0',
    'apiVersion': 1,
    'permissions': permissions,
  });

  final archive = Archive()
    ..addFile(
      ArchiveFile('metadata.json', metadata.length, utf8.encode(metadata)),
    )
    ..addFile(ArchiveFile('extension.js', script.length, utf8.encode(script)));

  return GmxArchive.read(Uint8List.fromList(ZipEncoder().encode(archive)));
}
