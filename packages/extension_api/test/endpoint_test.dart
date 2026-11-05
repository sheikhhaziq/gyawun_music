import 'package:extension_api/extension_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps any JSON value unchanged', () {
    for (final v in [
      'token',
      5,
      true,
      [1, 2],
      {'browseId': 'abc', 'params': null},
    ]) {
      expect(Endpoint.parse<Object>(v, 'e').toJson(), v);
    }
  });

  test('rejects null', () {
    expect(() => Endpoint.parse<Object>(null, 'e'), throwsFormatException);
  });

  test('parseOptional returns null for null and parses otherwise', () {
    expect(Endpoint.parseOptional<Object>(null, 'e'), isNull);
    expect(Endpoint.parseOptional<Object>('x', 'e')!.toJson(), 'x');
  });

  test('rejects data that is not JSON', () {
    expect(() => Endpoint.parse<Object>(Object(), 'e'), throwsFormatException);
  });

  test('the error names the path', () {
    expect(
      () => Endpoint.parse<Object>(null, 'browse.continuation'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('browse.continuation'),
        ),
      ),
    );
  });

  test('enforces the size limit at the boundary', () {
    // jsonEncode adds two quote characters around a string.
    final fits = 'a' * (Endpoint.maxBytes - 2);

    expect(() => Endpoint.parse<Object>(fits, 'e'), returnsNormally);
    expect(
      () => Endpoint.parse<Object>('${fits}a', 'e'),
      throwsFormatException,
    );
  });

  test('counts bytes, not characters', () {
    // Each emoji is 4 bytes in UTF-8.
    expect(
      () => Endpoint.parse<Object>('🎵' * 4200, 'e'),
      throwsFormatException,
    );
  });

  test('accepts a realistic long continuation token', () {
    expect(
      () =>
          Endpoint.parse<Object>({'token': 'x' * 3000, 'itct': 'y' * 500}, 'e'),
      returnsNormally,
    );
  });
}
