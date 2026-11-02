import 'dart:async';
import 'dart:convert';

import 'package:extension_capabilities/extension_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

typedef Responder = http.StreamedResponse Function(http.BaseRequest request);

http.StreamedResponse reply(
  String body, {
  int status = 200,
  Map<String, String> headers = const {},
}) => http.StreamedResponse(
  Stream.value(utf8.encode(body)),
  status,
  headers: headers,
);

void main() {
  late List<http.BaseRequest> seen;

  NetworkCapability build(
    Responder responder, {
    Iterable<String> domains = const ['api.example.com', 'other.example.com'],
    Duration timeout = const Duration(seconds: 5),
    int maxResponseBytes = 1000,
    int maxRedirects = 3,
  }) {
    seen = [];
    final client = MockClient.streaming((request, _) async {
      seen.add(request);
      return responder(request);
    });
    return NetworkCapability(
      policy: DomainPolicy(domains),
      client: client,
      timeout: timeout,
      maxResponseBytes: maxResponseBytes,
      maxRedirects: maxRedirects,
    );
  }

  test('is named network', () {
    expect(build((_) => reply('')).name, 'network');
  });

  group('fetch', () {
    test('returns status, headers and body', () async {
      final net = build(
        (_) => reply(
          'hello',
          status: 201,
          headers: {'content-type': 'text/plain'},
        ),
      );

      final result = await net.handle('fetch', {
        'url': 'https://api.example.com/x',
      }) as Map;

      expect(result['status'], 201);
      expect(result['body'], 'hello');
      expect((result['headers'] as Map)['content-type'], 'text/plain');
    });

    test('defaults to GET', () async {
      final net = build((_) => reply(''));

      await net.handle('fetch', {'url': 'https://api.example.com/'});

      expect(seen.single.method, 'GET');
    });

    test('sends the method, headers and body', () async {
      final net = build((_) => reply(''));

      await net.handle('fetch', {
        'url': 'https://api.example.com/items',
        'method': 'post',
        'headers': {'X-Token': 'abc'},
        'body': '{"a":1}',
      });

      final request = seen.single as http.Request;
      expect(request.method, 'POST');
      expect(request.headers['x-token'], 'abc');
      expect(request.body, '{"a":1}');
    });

    test('decodes unicode bodies', () async {
      final net = build((_) => reply('héllo 🎵'));

      final result =
          await net.handle('fetch', {'url': 'https://api.example.com/'}) as Map;

      expect(result['body'], 'héllo 🎵');
    });

    test('a 404 is a result, not an error', () async {
      final net = build((_) => reply('nope', status: 404));

      final result =
          await net.handle('fetch', {'url': 'https://api.example.com/'}) as Map;

      expect(result['status'], 404);
    });
  });

  group('policy', () {
    test('blocks a forbidden domain before any request is made', () async {
      final net = build((_) => reply(''));

      await expectLater(
        net.handle('fetch', {'url': 'https://evil.com/'}),
        throwsStateError,
      );
      expect(seen, isEmpty);
    });

    test('blocks http', () async {
      final net = build((_) => reply(''));

      await expectLater(
        net.handle('fetch', {'url': 'http://api.example.com/'}),
        throwsArgumentError,
      );
      expect(seen, isEmpty);
    });
  });

  group('redirects', () {
    test('follows a redirect to an allowed host', () async {
      final net = build(
        (request) => request.url.host == 'api.example.com'
            ? reply(
                '',
                status: 302,
                headers: {'location': 'https://other.example.com/final'},
              )
            : reply('arrived'),
      );

      final result = await net.handle('fetch', {
        'url': 'https://api.example.com/start',
      }) as Map;

      expect(result['body'], 'arrived');
      expect(seen.map((r) => r.url.host), [
        'api.example.com',
        'other.example.com',
      ]);
    });

    test('blocks a redirect to a forbidden host', () async {
      final net = build(
        (_) =>
            reply('', status: 302, headers: {'location': 'https://evil.com/'}),
      );

      await expectLater(
        net.handle('fetch', {'url': 'https://api.example.com/'}),
        throwsStateError,
      );
      expect(seen, hasLength(1));
    });

    test('blocks a redirect downgrade to http', () async {
      final net = build(
        (_) => reply(
          '',
          status: 302,
          headers: {'location': 'http://api.example.com/'},
        ),
      );

      await expectLater(
        net.handle('fetch', {'url': 'https://api.example.com/'}),
        throwsArgumentError,
      );
    });

    test('resolves a relative redirect', () async {
      final net = build(
        (request) => request.url.path == '/start'
            ? reply('', status: 301, headers: {'location': '/final'})
            : reply('ok'),
      );

      final result = await net.handle('fetch', {
        'url': 'https://api.example.com/start',
      }) as Map;

      expect(result['body'], 'ok');
      expect(seen.last.url.path, '/final');
    });

    test('drops credentials on a cross-host redirect', () async {
      final net = build(
        (request) => request.url.host == 'api.example.com'
            ? reply(
                '',
                status: 302,
                headers: {'location': 'https://other.example.com/'},
              )
            : reply('ok'),
      );

      await net.handle('fetch', {
        'url': 'https://api.example.com/',
        'headers': {'Authorization': 'secret', 'Cookie': 'a=b', 'X-Keep': '1'},
      });

      expect(seen.first.headers['authorization'], 'secret');
      expect(seen.last.headers.containsKey('authorization'), isFalse);
      expect(seen.last.headers.containsKey('cookie'), isFalse);
      expect(seen.last.headers['x-keep'], '1');
    });

    test('keeps credentials on a same-host redirect', () async {
      final net = build(
        (request) => request.url.path == '/a'
            ? reply('', status: 302, headers: {'location': '/b'})
            : reply('ok'),
      );

      await net.handle('fetch', {
        'url': 'https://api.example.com/a',
        'headers': {'Authorization': 'secret'},
      });

      expect(seen.last.headers['authorization'], 'secret');
    });

    test('turns a POST into a GET without a body on 302', () async {
      final net = build(
        (request) => request.url.path == '/a'
            ? reply('', status: 302, headers: {'location': '/b'})
            : reply('ok'),
      );

      await net.handle('fetch', {
        'url': 'https://api.example.com/a',
        'method': 'POST',
        'body': 'data',
      });

      final last = seen.last as http.Request;
      expect(last.method, 'GET');
      expect(last.body, isEmpty);
    });

    test('keeps the method on a 307', () async {
      final net = build(
        (request) => request.url.path == '/a'
            ? reply('', status: 307, headers: {'location': '/b'})
            : reply('ok'),
      );

      await net.handle('fetch', {
        'url': 'https://api.example.com/a',
        'method': 'POST',
        'body': 'data',
      });

      final last = seen.last as http.Request;
      expect(last.method, 'POST');
      expect(last.body, 'data');
    });

    test('fails after too many redirects', () async {
      final net = build(
        (_) => reply('', status: 302, headers: {'location': '/loop'}),
        maxRedirects: 3,
      );

      await expectLater(
        net.handle('fetch', {'url': 'https://api.example.com/loop'}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Too many redirects'),
          ),
        ),
      );
      expect(seen, hasLength(4)); // the first request plus 3 redirects
    });
  });

  group('limits', () {
    test('accepts a body exactly at the limit', () async {
      final net = build((_) => reply('a' * 1000));

      final result =
          await net.handle('fetch', {'url': 'https://api.example.com/'}) as Map;

      expect((result['body'] as String).length, 1000);
    });

    test('rejects a body over the limit', () async {
      final net = build((_) => reply('a' * 1001));

      await expectLater(
        net.handle('fetch', {'url': 'https://api.example.com/'}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('exceeds'),
          ),
        ),
      );
    });

    test('rejects a body that exceeds the limit across chunks', () async {
      final net = build(
        (_) => http.StreamedResponse(
          Stream.fromIterable([utf8.encode('a' * 600), utf8.encode('a' * 600)]),
          200,
        ),
      );

      await expectLater(
        net.handle('fetch', {'url': 'https://api.example.com/'}),
        throwsStateError,
      );
    });

    test('times out a slow request', () async {
      final net = build(
        (_) => http.StreamedResponse(
          Stream<List<int>>.fromFuture(
            Future<List<int>>.delayed(const Duration(seconds: 2), () => []),
          ),
          200,
        ),
        timeout: const Duration(milliseconds: 100),
      );

      await expectLater(
        net.handle('fetch', {'url': 'https://api.example.com/'}),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  group('input validation', () {
    test('rejects a missing url', () async {
      final net = build((_) => reply(''));

      await expectLater(net.handle('fetch', {}), throwsArgumentError);
    });

    test('rejects a non-string url', () async {
      final net = build((_) => reply(''));

      await expectLater(net.handle('fetch', {'url': 5}), throwsArgumentError);
    });

    test('rejects an unknown method', () {
      final net = build((_) => reply(''));

      expect(() => net.handle('upload', {}), throwsArgumentError);
    });
  });
}
