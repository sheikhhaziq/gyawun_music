import 'dart:async';
import 'dart:convert';

import 'package:extension_repository/extension_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _url = Uri.parse('https://repo.example.com/index.json');

final _body = jsonEncode({
  'schema': 1,
  'name': 'Test',
  'extensions': [
    {
      'id': 'com.example.music',
      'name': 'Example',
      'version': '1.0.0',
      'apiVersion': 1,
      'download': 'https://example.com/a.gmx',
      'sha256': 'a' * 64,
      'size': 100,
    },
  ],
});

http.StreamedResponse reply(
  String body, {
  int status = 200,
  Map<String, String> headers = const {},
  int? contentLength,
}) => http.StreamedResponse(
  Stream.value(utf8.encode(body)),
  status,
  headers: headers,
  contentLength: contentLength,
);

Matcher fetchFails(String text) => throwsA(
  isA<RepositoryFetchException>().having(
    (e) => e.message,
    'message',
    contains(text),
  ),
);

void main() {
  late List<http.BaseRequest> seen;

  RepositoryClient build(
    http.StreamedResponse Function(http.BaseRequest) responder, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    seen = [];
    return RepositoryClient(
      client: MockClient.streaming((request, _) async {
        seen.add(request);
        return responder(request);
      }),
      timeout: timeout,
    );
  }

  group('success', () {
    test('returns the index, raw source and etag', () async {
      final client = build((_) => reply(_body, headers: {'etag': '"v1"'}));

      final result = await client.fetch(_url) as RepositoryFetched;

      expect(result.index.name, 'Test');
      expect(result.index.entries.single.id, 'com.example.music');
      expect(result.source, _body);
      expect(result.etag, '"v1"');
    });

    test('etag is null when the server sends none', () async {
      final client = build((_) => reply(_body));

      final result = await client.fetch(_url) as RepositoryFetched;

      expect(result.etag, isNull);
    });

    test('an over-long etag is ignored', () async {
      final client = build((_) => reply(_body, headers: {'etag': 'x' * 300}));

      final result = await client.fetch(_url) as RepositoryFetched;

      expect(result.etag, isNull);
    });

    test('sends accept and no if-none-match by default', () async {
      final client = build((_) => reply(_body));

      await client.fetch(_url);

      expect(seen.single.headers['accept'], 'application/json');
      expect(seen.single.headers.containsKey('if-none-match'), isFalse);
    });
  });

  group('etag', () {
    test('is sent as if-none-match', () async {
      final client = build((_) => reply(_body));

      await client.fetch(_url, etag: '"v1"');

      expect(seen.single.headers['if-none-match'], '"v1"');
    });

    test('a 304 means not modified', () async {
      final client = build((_) => reply('', status: 304));

      final result = await client.fetch(_url, etag: '"v1"');

      expect(result, isA<RepositoryNotModified>());
    });

    test('a 304 without a request etag is an error', () async {
      final client = build((_) => reply('', status: 304));

      await expectLater(client.fetch(_url), fetchFails('HTTP 304'));
    });
  });

  group('errors', () {
    test('a non-200 status', () async {
      final client = build((_) => reply('nope', status: 404));

      await expectLater(client.fetch(_url), fetchFails('HTTP 404'));
    });

    test('a client exception becomes a fetch exception', () async {
      final client = RepositoryClient(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );

      await expectLater(client.fetch(_url), fetchFails('offline'));
    });

    test('a slow server times out', () async {
      final client = build(
        (_) => http.StreamedResponse(
          Stream<List<int>>.fromFuture(
            Future<List<int>>.delayed(const Duration(seconds: 2), () => []),
          ),
          200,
        ),
        timeout: const Duration(milliseconds: 100),
      );

      await expectLater(client.fetch(_url), fetchFails('Timed out'));
    });

    test('invalid JSON is a FormatException, not a fetch exception', () async {
      final client = build((_) => reply('{nope'));

      await expectLater(client.fetch(_url), throwsFormatException);
    });

    test('an unsupported schema is a FormatException', () async {
      final client = build((_) => reply('{"schema":2,"extensions":[]}'));

      await expectLater(client.fetch(_url), throwsFormatException);
    });

    test('invalid UTF-8 is a FormatException', () async {
      final client = build(
        (_) => http.StreamedResponse(Stream.value([0xff, 0xfe, 0xfd]), 200),
      );

      await expectLater(client.fetch(_url), throwsFormatException);
    });
  });

  group('url rules', () {
    for (final bad in [
      'http://repo.example.com/index.json',
      'file:///etc/passwd',
      'https://user:pass@repo.example.com/index.json',
      'https:///index.json',
    ]) {
      test('refuses $bad without a request', () async {
        final client = build((_) => reply(_body));

        await expectLater(
          client.fetch(Uri.parse(bad)),
          fetchFails('Only https'),
        );
        expect(seen, isEmpty);
      });
    }
  });

  group('redirects', () {
    test('follows a redirect to another https URL', () async {
      final client = build(
        (r) => r.url.host == 'repo.example.com'
            ? reply(
                '',
                status: 302,
                headers: {'location': 'https://cdn.example.com/i.json'},
              )
            : reply(_body),
      );

      final result = await client.fetch(_url);

      expect(result, isA<RepositoryFetched>());
      expect(seen.map((r) => r.url.host), [
        'repo.example.com',
        'cdn.example.com',
      ]);
    });

    test('resolves a relative redirect', () async {
      final client = build(
        (r) => r.url.path == '/index.json'
            ? reply('', status: 301, headers: {'location': '/v2/index.json'})
            : reply(_body),
      );

      await client.fetch(_url);

      expect(seen.last.url.path, '/v2/index.json');
    });

    test('blocks a downgrade to http', () async {
      final client = build(
        (_) => reply(
          '',
          status: 302,
          headers: {'location': 'http://repo.example.com/i.json'},
        ),
      );

      await expectLater(client.fetch(_url), fetchFails('Only https'));
      expect(seen, hasLength(1));
    });

    test('fails after too many redirects', () async {
      final client = build(
        (_) => reply('', status: 302, headers: {'location': '/loop'}),
      );

      await expectLater(client.fetch(_url), fetchFails('Too many redirects'));
      expect(seen, hasLength(4)); // the first request plus 3 redirects
    });
  });

  group('size limit', () {
    final tooBig = 'a' * (RepositoryIndex.maxBytes + 1);

    test('rejects a body over the limit', () async {
      final client = build((_) => reply(tooBig));

      await expectLater(client.fetch(_url), fetchFails('too large'));
    });

    test('rejects a body that exceeds the limit across chunks', () async {
      final half = utf8.encode('a' * (RepositoryIndex.maxBytes ~/ 2 + 1));
      final client = build(
        (_) => http.StreamedResponse(Stream.fromIterable([half, half]), 200),
      );

      await expectLater(client.fetch(_url), fetchFails('too large'));
    });

    test(
      'rejects early when content-length already exceeds the limit',
      () async {
        final client = build(
          (_) => reply('{}', contentLength: RepositoryIndex.maxBytes + 1),
        );

        await expectLater(client.fetch(_url), fetchFails('too large'));
      },
    );
  });
}
