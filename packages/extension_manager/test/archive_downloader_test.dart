import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:extension_manager/extension_manager.dart';
import 'package:extension_repository/extension_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _bytes = Uint8List.fromList(List.generate(100, (i) => i));

RepositoryEntry entryFor(
  Uint8List bytes, {
  int? size,
  String? hash,
  String url = 'https://example.com/a.gmx',
}) => RepositoryIndex.parse(
  jsonEncode({
    'schema': 1,
    'extensions': [
      {
        'id': 'com.example.music',
        'name': 'Example',
        'version': '1.0.0',
        'apiVersion': 1,
        'download': url,
        'sha256': hash ?? sha256.convert(bytes).toString(),
        'size': size ?? bytes.length,
      },
    ],
  }),
).entries.single;

http.StreamedResponse reply(
  List<int> body, {
  int status = 200,
  Map<String, String> headers = const {},
  int? contentLength,
}) => http.StreamedResponse(
  Stream.value(body),
  status,
  headers: headers,
  contentLength: contentLength,
);

Matcher failsWith(String text) => throwsA(
  isA<ArchiveDownloadException>().having(
    (e) => e.message,
    'message',
    contains(text),
  ),
);

void main() {
  late List<http.BaseRequest> seen;

  ArchiveDownloader build(
    http.StreamedResponse Function(http.BaseRequest) responder, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    seen = [];
    return ArchiveDownloader(
      client: MockClient.streaming((request, _) async {
        seen.add(request);
        return responder(request);
      }),
      timeout: timeout,
    );
  }

  test('returns verified bytes', () async {
    final d = build((_) => reply(_bytes));

    expect(await d.download(entryFor(_bytes)), _bytes);
  });

  group('verification', () {
    test('a wrong hash is rejected', () async {
      final d = build((_) => reply(_bytes));

      await expectLater(
        d.download(entryFor(_bytes, hash: 'b' * 64)),
        failsWith('SHA-256'),
      );
    });

    test('changed content with the right size is rejected', () async {
      final tampered = Uint8List.fromList(List.filled(100, 7));
      final d = build((_) => reply(tampered));

      await expectLater(d.download(entryFor(_bytes)), failsWith('SHA-256'));
    });

    test('a smaller body than declared is rejected', () async {
      final d = build((_) => reply(_bytes.sublist(0, 50)));

      await expectLater(d.download(entryFor(_bytes)), failsWith('size is 50'));
    });
  });

  group('size limit', () {
    test('a larger body than declared is rejected', () async {
      final big = Uint8List(101);
      final d = build((_) => reply(big));

      await expectLater(
        d.download(entryFor(_bytes)),
        failsWith('larger than declared'),
      );
    });

    test('the limit applies across chunks', () async {
      final d = build(
        (_) => http.StreamedResponse(
          Stream.fromIterable([Uint8List(60), Uint8List(60)]),
          200,
        ),
      );

      await expectLater(
        d.download(entryFor(_bytes)),
        failsWith('larger than declared'),
      );
    });

    test('content-length over the limit is rejected early', () async {
      final d = build((_) => reply(_bytes, contentLength: 5000));

      await expectLater(
        d.download(entryFor(_bytes)),
        failsWith('larger than declared'),
      );
    });
  });

  group('errors', () {
    test('a non-200 status', () async {
      final d = build((_) => reply([], status: 404));

      await expectLater(d.download(entryFor(_bytes)), failsWith('HTTP 404'));
    });

    test('a client exception', () async {
      final d = ArchiveDownloader(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );

      await expectLater(d.download(entryFor(_bytes)), failsWith('offline'));
    });

    test('a slow server times out', () async {
      final d = build(
        (_) => http.StreamedResponse(
          Stream<List<int>>.fromFuture(
            Future<List<int>>.delayed(const Duration(seconds: 2), () => []),
          ),
          200,
        ),
        timeout: const Duration(milliseconds: 100),
      );

      await expectLater(d.download(entryFor(_bytes)), failsWith('Timed out'));
    });
  });

  group('redirects', () {
    test('follows a redirect to another https URL', () async {
      final d = build(
        (r) => r.url.host == 'example.com'
            ? reply(
                [],
                status: 302,
                headers: {'location': 'https://cdn.example.com/a.gmx'},
              )
            : reply(_bytes),
      );

      expect(await d.download(entryFor(_bytes)), _bytes);
      expect(seen.map((r) => r.url.host), ['example.com', 'cdn.example.com']);
    });

    test('resolves a relative redirect', () async {
      final d = build(
        (r) => r.url.path == '/a.gmx'
            ? reply([], status: 301, headers: {'location': '/v2/a.gmx'})
            : reply(_bytes),
      );

      await d.download(entryFor(_bytes));

      expect(seen.last.url.path, '/v2/a.gmx');
    });

    test('blocks a downgrade to http', () async {
      final d = build(
        (_) => reply(
          [],
          status: 302,
          headers: {'location': 'http://example.com/a.gmx'},
        ),
      );

      await expectLater(d.download(entryFor(_bytes)), failsWith('Only https'));
      expect(seen, hasLength(1));
    });

    test('fails after too many redirects', () async {
      final d = build(
        (_) => reply([], status: 302, headers: {'location': '/loop'}),
      );

      await expectLater(
        d.download(entryFor(_bytes)),
        failsWith('Too many redirects'),
      );
      expect(seen, hasLength(4)); // the first request plus 3 redirects
    });
  });
}
