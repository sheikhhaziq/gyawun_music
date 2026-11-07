import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:gmx/gmx.dart';

/// Builds a valid archive in memory and reads it back through the real
/// [GmxArchive.read], so tests exercise the same path as a real install.
///
/// Most tests exercise methods other than browse, so by default the script's
/// methods are spread over a no-op `browse`. A test's own `browse` wins.
/// Pass `withBrowse: false` to test the browse requirement itself.
GmxArchive buildArchive(
  String script, {
  Map<String, Object?> permissions = const {},
  String id = 'com.example.test',
  bool withBrowse = true,
}) {
  final source = withBrowse
      ? '(ctx) => { const m = ($script)(ctx); '
            'return { browse: async () => ({}), ...m }; }'
      : script;

  final metadata = utf8.encode(
    jsonEncode({
      'id': id,
      'name': 'Test',
      'version': '1.0.0',
      'apiVersion': 1,
      'provides': ['browse'],
      'permissions': permissions,
    }),
  );
  final extension = utf8.encode(source);

  final archive = Archive()
    ..addFile(ArchiveFile('metadata.json', metadata.length, metadata))
    ..addFile(ArchiveFile('extension.js', extension.length, extension));

  return GmxArchive.read(Uint8List.fromList(ZipEncoder().encode(archive)));
}
