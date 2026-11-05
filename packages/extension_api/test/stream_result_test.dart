import 'package:extension_api/extension_api.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> source([Map<String, Object?> extra = const {}]) => {
  'url': 'https://cdn.example.com/a.m4a',
  ...extra,
};

StreamResult parse(Object? v) => StreamResult.parse(v);

Matcher failsWith(String text) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(text)),
);

void main() {
  test('parses a minimal result', () {
    final r = parse({
      'sources': [source()],
    });

    expect(r.sources.single.url, Uri.parse('https://cdn.example.com/a.m4a'));
    expect(r.sources.single.headers, isEmpty);
    expect(r.expiresInSeconds, isNull);
  });

  test('parses every field', () {
    final r = parse({
      'sources': [
        source({
          'mimeType': 'audio/mp4',
          'bitrate': 128000,
          'headers': {'Referer': 'https://example.com', 'user-agent': 'x'},
        }),
      ],
      'expiresInSeconds': 3600,
    });

    final s = r.sources.single;
    expect(s.mimeType, 'audio/mp4');
    expect(s.bitrate, 128000);
    expect(s.headers, {'referer': 'https://example.com', 'user-agent': 'x'});
    expect(r.expiresInSeconds, 3600);
  });

  test('keeps source order', () {
    final r = parse({
      'sources': [
        source({'url': 'https://a.com/1'}),
        source({'url': 'https://a.com/2'}),
      ],
    });

    expect(r.sources.map((s) => s.url.path), ['/1', '/2']);
  });

  group('sources', () {
    test('must be present and non-empty', () {
      expect(() => parse({}), failsWith('must not be empty'));
      expect(() => parse({'sources': []}), failsWith('must not be empty'));
    });

    test('at most 10', () {
      List<Object?> n(int c) => [for (var i = 0; i < c; i++) source()];

      expect(() => parse({'sources': n(10)}), returnsNormally);
      expect(() => parse({'sources': n(11)}), throwsFormatException);
    });

    test('a bad entry names its index', () {
      expect(
        () => parse({
          'sources': [
            source(),
            {'url': 'http://a.com/x'},
          ],
        }),
        failsWith('stream.sources[1].url'),
      );
    });

    test('the result must be an object', () {
      expect(() => parse([]), throwsFormatException);
      expect(() => parse(null), throwsFormatException);
    });
  });

  group('url', () {
    for (final bad in [
      'http://a.com/x',
      'file:///x',
      'not a url',
      'https://u:p@a.com/x',
    ]) {
      test('rejects $bad', () {
        expect(
          () => parse({
            'sources': [
              source({'url': bad}),
            ],
          }),
          throwsFormatException,
        );
      });
    }

    test('allows up to 4096 characters', () {
      const p = 'https://a.com/';

      expect(
        () => parse({
          'sources': [
            source({'url': p + 'a' * (4096 - p.length)}),
          ],
        }),
        returnsNormally,
      );
      expect(
        () => parse({
          'sources': [
            source({'url': p + 'a' * (4097 - p.length)}),
          ],
        }),
        throwsFormatException,
      );
    });
  });

  group('bitrate and mimeType', () {
    for (final bad in [0, -1, 10000001, 1.5, '128']) {
      test('rejects bitrate $bad', () {
        expect(
          () => parse({
            'sources': [
              source({'bitrate': bad}),
            ],
          }),
          throwsFormatException,
        );
      });
    }

    test('rejects a mimeType over 100 characters', () {
      expect(
        () => parse({
          'sources': [
            source({'mimeType': 'a' * 101}),
          ],
        }),
        throwsFormatException,
      );
    });
  });

  group('headers', () {
    Object? withHeaders(Object? h) => {
      'sources': [
        source({'headers': h}),
      ],
    };

    for (final name in [
      'user-agent',
      'referer',
      'origin',
      'User-Agent',
      'ORIGIN',
    ]) {
      test('allows $name', () {
        expect(() => parse(withHeaders({name: 'v'})), returnsNormally);
      });
    }

    for (final name in ['cookie', 'authorization', 'host', 'x-custom']) {
      test('rejects $name', () {
        expect(
          () => parse(withHeaders({name: 'v'})),
          failsWith('not an allowed header'),
        );
      });
    }

    test('rejects a duplicate after lowercasing', () {
      expect(
        () => parse(withHeaders({'Referer': 'a', 'referer': 'b'})),
        failsWith('duplicate'),
      );
    });

    for (final bad in ['a\r\nX-Evil: 1', 'a\nb', 'a\x00b']) {
      test('rejects control characters in a value', () {
        expect(
          () => parse(withHeaders({'referer': bad})),
          failsWith('invalid characters'),
        );
      });
    }

    test('rejects a value over 500 characters', () {
      expect(() => parse(withHeaders({'referer': 'a' * 500})), returnsNormally);
      expect(
        () => parse(withHeaders({'referer': 'a' * 501})),
        throwsFormatException,
      );
    });

    test('rejects non-string values and non-objects', () {
      expect(() => parse(withHeaders({'referer': 1})), throwsFormatException);
      expect(() => parse(withHeaders([])), throwsFormatException);
    });
  });

  group('expiresInSeconds', () {
    Object? withExpiry(Object? e) => {
      'sources': [source()],
      'expiresInSeconds': e,
    };

    test('accepts the bounds', () {
      expect(parse(withExpiry(1)).expiresInSeconds, 1);
      expect(
        parse(withExpiry(StreamResult.maxExpirySeconds)).expiresInSeconds,
        StreamResult.maxExpirySeconds,
      );
    });

    for (final bad in [0, -5, StreamResult.maxExpirySeconds + 1, 1.5, '60']) {
      test('rejects $bad', () {
        expect(() => parse(withExpiry(bad)), throwsFormatException);
      });
    }
  });

  test('works as the parse target for an endpoint', () {
    final ref = StreamRef.parse(
      JsonObject.of({'type': 'endpoint', 'endpoint': 'tok'}, 's'),
    ) as EndpointStream;

    expect(ref.endpoint, isA<Endpoint<StreamResult>>());
  });
}
