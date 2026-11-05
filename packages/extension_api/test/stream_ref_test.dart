import 'package:extension_api/extension_api.dart';
import 'package:flutter_test/flutter_test.dart';

StreamRef parse(Object? v) => StreamRef.parse(JsonObject.of(v, 's'));

void main() {
  test('parses an endpoint stream and keeps the endpoint', () {
    final s = parse({
      'type': 'endpoint',
      'endpoint': {'track': 7},
    });

    expect(s, isA<EndpointStream>());
    expect((s as EndpointStream).endpoint.toJson(), {'track': 7});
  });

  test('parses a youtube stream', () {
    final s = parse({'type': 'youtube', 'id': 'dQw4w9WgXcQ'});

    expect((s as YoutubeStream).videoId, 'dQw4w9WgXcQ');
  });

  test('accepts ids with - and _', () {
    expect(
      () => parse({'type': 'youtube', 'id': 'a-b_c-d_e-f'}),
      returnsNormally,
    );
  });

  for (final bad in [
    'short',
    'dQw4w9WgXcQ1',
    'dQw4w9WgXc!',
    'dQw4w9WgX c',
    '',
  ]) {
    test('rejects the video id "$bad"', () {
      expect(
        () => parse({'type': 'youtube', 'id': bad}),
        throwsFormatException,
      );
    });
  }

  test('rejects a missing endpoint', () {
    expect(() => parse({'type': 'endpoint'}), throwsFormatException);
  });

  test('rejects an unknown or missing type', () {
    expect(
      () => parse({'type': 'direct', 'url': 'https://a.com'}),
      throwsFormatException,
    );
    expect(() => parse({}), throwsFormatException);
  });

  test('parseOptional is null when absent', () {
    expect(StreamRef.parseOptional(JsonObject.of({}, 'p'), 'stream'), isNull);
  });
}
