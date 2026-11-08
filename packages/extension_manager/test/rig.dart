import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:extension_manager/extension_manager.dart';
import 'package:extension_repository/extension_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fakes.dart';

final repoA = Uri.parse('https://a.example.com/index.json');
final repoB = Uri.parse('https://b.example.com/index.json');

Uint8List gmx({
  String id = 'com.example.music',
  String version = '1.0.0',
  int apiVersion = 1,
  Map<String, Object?> permissions = const {},
}) {
  final meta = utf8.encode(
    jsonEncode({
      'id': id,
      'name': 'Example',
      'version': version,
      'apiVersion': apiVersion,
      'provides': ['browse'],
      'permissions': permissions,
    }),
  );
  final js = utf8.encode('(ctx) => ({ browse: async () => ({}) })');
  final archive = Archive()
    ..addFile(ArchiveFile('metadata.json', meta.length, meta))
    ..addFile(ArchiveFile('extension.js', js.length, js));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// An entry describing [bytes]. Pass different id, version or apiVersion to
/// simulate a repository that lies.
RepositoryEntry entryFor(
  Uint8List bytes, {
  String id = 'com.example.music',
  String version = '1.0.0',
  int apiVersion = 1,
}) => RepositoryIndex.parse(
  jsonEncode({
    'schema': 1,
    'extensions': [
      {
        'id': id,
        'name': 'Example',
        'version': version,
        'apiVersion': apiVersion,
        'download': 'https://example.com/a.gmx',
        'sha256': sha256.convert(bytes).toString(),
        'size': bytes.length,
      },
    ],
  }),
).entries.single;

class Rig {
  Rig({int supportedApi = 1}) {
    manager = ExtensionManager(
      store: store,
      files: files,
      downloader: ArchiveDownloader(
        client: MockClient.streaming((request, _) async {
          requests++;
          return http.StreamedResponse(Stream.value(served), 200);
        }),
      ),
      supportedApiVersion: supportedApi,
      clearStorage: (id) async => cleared.add(id),
      clock: () => now,
    );
  }

  final store = InMemoryStore();
  final files = InMemoryFiles();
  final cleared = <String>[];
  final prompts = <InstallPrompt>[];
  late final ExtensionManager manager;

  Uint8List served = Uint8List(0);
  int requests = 0;
  DateTime now = DateTime.utc(2025, 1, 1);

  Future<InstalledRecord?> install(
    Uint8List bytes, {
    String id = 'com.example.music',
    String version = '1.0.0',
    int api = 1,
    Uri? repo,
    bool approve = true,
  }) {
    served = bytes;
    return manager.install(
      entryFor(bytes, id: id, version: version, apiVersion: api),
      repo ?? repoA,
      confirm: (prompt) async {
        prompts.add(prompt);
        return approve;
      },
    );
  }
}
