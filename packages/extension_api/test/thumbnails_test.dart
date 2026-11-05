import 'package:extension_api/extension_api.dart';
import 'package:flutter_test/flutter_test.dart';

Thumbnails parse(Object? v) => Thumbnails.parse(JsonObject.of(v, 't'));

void main() {
  test('parses all sizes', () {
    final t = parse({
      'small': 'https://a.com/s.jpg',
      'medium': 'https://a.com/m.jpg',
      'large': 'https://a.com/l.jpg',
    });

    expect(t.small, Uri.parse('https://a.com/s.jpg'));
    expect(t.medium, Uri.parse('https://a.com/m.jpg'));
    expect(t.smallest, Uri.parse('https://a.com/s.jpg'));
    expect(t.largest, Uri.parse('https://a.com/l.jpg'));
  });

  test('one size is enough, and the others fall back to it', () {
    final t = parse({'medium': 'https://a.com/m.jpg'});

    expect(t.smallest, t.largest);
    expect(t.small, isNull);
  });

  test('falls back to the nearest available size', () {
    final t = parse({
      'small': 'https://a.com/s.jpg',
      'large': 'https://a.com/l.jpg',
    });

    expect(t.smallest, Uri.parse('https://a.com/s.jpg'));
    expect(t.largest, Uri.parse('https://a.com/l.jpg'));
  });

  test('rejects an empty map', () {
    expect(() => parse({}), throwsFormatException);
  });

  for (final bad in [
    'http://a.com/x.jpg',
    'file:///etc/passwd',
    'javascript:alert(1)',
    'data:image/png;base64,AAAA',
    '//a.com/x.jpg',
    'not a url',
    'https:///x.jpg',
    'https://user:pass@a.com/x.jpg',
  ]) {
    test('rejects $bad', () {
      expect(() => parse({'small': bad}), throwsFormatException);
    });
  }

  test('rejects a non-string value', () {
    expect(() => parse({'small': 5}), throwsFormatException);
  });

  test('rejects one bad URL even if others are valid', () {
    expect(
      () => parse({
        'small': 'https://a.com/s.jpg',
        'large': 'http://a.com/l.jpg',
      }),
      throwsFormatException,
    );
  });

  test('accepts a URL at the length limit and rejects one over it', () {
    const prefix = 'https://a.com/';
    expect(
      () => parse({'small': prefix + 'a' * (2048 - prefix.length)}),
      returnsNormally,
    );
    expect(
      () => parse({'small': prefix + 'a' * (2049 - prefix.length)}),
      throwsFormatException,
    );
  });

  test('the error names the field', () {
    expect(
      () => parse({'small': 'http://a.com/x'}),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('t.small'),
        ),
      ),
    );
  });

  test('ignores unknown keys', () {
    expect(
      () => parse({'small': 'https://a.com/s.jpg', 'huge': 'x'}),
      returnsNormally,
    );
  });

  group('parseOptional', () {
    test('is null when the key is absent', () {
      expect(
        Thumbnails.parseOptional(JsonObject.of({}, 'p'), 'thumbs'),
        isNull,
      );
    });

    test('parses when present', () {
      final parent = JsonObject.of({
        'thumbs': {'small': 'https://a.com/s.jpg'},
      }, 'p');

      expect(Thumbnails.parseOptional(parent, 'thumbs')!.small, isNotNull);
    });

    test('errors use the full path', () {
      final parent = JsonObject.of({
        'thumbs': {'small': 'http://a.com/s.jpg'},
      }, 'p');

      expect(
        () => Thumbnails.parseOptional(parent, 'thumbs'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('p.thumbs.small'),
          ),
        ),
      );
    });
  });
}
