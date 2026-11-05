import 'package:extension_api/extension_api.dart';
import 'package:flutter_test/flutter_test.dart';

QueueResult parse(Object? v) => QueueResult.parse(v);

Map<String, Object?> item(String kind) => {'kind': kind, 'title': 'T'};

void main() {
  test('an empty object is a valid empty queue', () {
    expect(parse({}).items, isEmpty);
  });

  for (final kind in ['song', 'video', 'episode']) {
    test('accepts $kind', () {
      expect(
        parse({
          'items': [item(kind)],
        }).items.single.kind.name,
        kind,
      );
    });
  }

  for (final kind in ['podcast', 'album', 'playlist', 'artist']) {
    test('rejects $kind', () {
      expect(
        () => parse({
          'items': [item(kind)],
        }),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('queue.items[0].kind'),
          ),
        ),
      );
    });
  }

  test('one bad item rejects the whole queue', () {
    expect(
      () => parse({
        'items': [item('song'), item('album')],
      }),
      throwsFormatException,
    );
  });

  test('parses a continuation for endless radio', () {
    expect(
      parse({
        'items': [item('song')],
        'continuation': 'more',
      }).continuation!.toJson(),
      'more',
    );
  });

  test('keeps stream refs on queued items', () {
    final r = parse({
      'items': [
        {
          'kind': 'song',
          'title': 'T',
          'stream': {'type': 'youtube', 'id': 'dQw4w9WgXcQ'},
        },
      ],
    });

    expect(r.items.single.stream, isA<YoutubeStream>());
  });

  test('limit: 500 ok, 501 rejected', () {
    List<Object?> n(int c) => [for (var i = 0; i < c; i++) item('song')];

    expect(() => parse({'items': n(500)}), returnsNormally);
    expect(() => parse({'items': n(501)}), throwsFormatException);
  });

  test('items are unmodifiable', () {
    expect(
      () => parse({
        'items': [item('song')],
      }).items.clear(),
      throwsUnsupportedError,
    );
  });
}
