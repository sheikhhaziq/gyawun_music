import 'package:extension_api/extension_api.dart';
import 'package:flutter_test/flutter_test.dart';

Item parse(Map<String, Object?> v) => Item.parse(JsonObject.of(v, 'i'));

Map<String, Object?> song() => {'kind': 'song', 'title': 'Title'};

void main() {
  test('parses the minimum', () {
    final item = parse(song());

    expect(item.kind, ItemKind.song);
    expect(item.title, 'Title');
    expect(item.artists, isEmpty);
    expect(item.stream, isNull);
  });

  test('parses every field', () {
    final item = parse({
      ...song(),
      'subtitle': 'Sub',
      'thumbnails': {'small': 'https://a.com/s.jpg'},
      'artists': [
        {
          'name': 'A',
          'browse': {'id': 1},
        },
        {'name': 'B'},
      ],
      'album': {'name': 'Album'},
      'playlist': {'name': 'List'},
      'durationMs': 215000,
      'browse': {'screen': 'song'},
      'play': {'a': 'play'},
      'radio': {'a': 'radio'},
      'shuffle': {'a': 'shuffle'},
      'stream': {'type': 'youtube', 'id': 'dQw4w9WgXcQ'},
    });

    expect(item.subtitle, 'Sub');
    expect(item.thumbnails!.small, isNotNull);
    expect(item.artists.map((a) => a.name), ['A', 'B']);
    expect(item.artists.first.browse!.toJson(), {'id': 1});
    expect(item.album!.name, 'Album');
    expect(item.playlist!.name, 'List');
    expect(item.durationMs, 215000);
    expect(item.browse!.toJson(), {'screen': 'song'});
    expect(item.play!.toJson(), {'a': 'play'});
    expect(item.radio!.toJson(), {'a': 'radio'});
    expect(item.shuffle!.toJson(), {'a': 'shuffle'});
    expect(item.stream, isA<YoutubeStream>());
  });

  test('ignores unknown keys', () {
    expect(() => parse({...song(), 'future': 1}), returnsNormally);
  });

  group('required fields', () {
    test('kind', () {
      expect(() => parse({'title': 'T'}), throwsFormatException);
      expect(() => parse({...song(), 'kind': 'track'}), throwsFormatException);
    });

    test('title', () {
      expect(() => parse({'kind': 'song'}), throwsFormatException);
      expect(() => parse({...song(), 'title': ''}), throwsFormatException);
    });
  });

  group('limits', () {
    test('subtitle over 300 characters', () {
      expect(() => parse({...song(), 'subtitle': 'a' * 300}), returnsNormally);
      expect(
        () => parse({...song(), 'subtitle': 'a' * 301}),
        throwsFormatException,
      );
    });

    test('artists over 20', () {
      List<Map<String, Object?>> artists(int n) => [
        for (var i = 0; i < n; i++) {'name': 'a$i'},
      ];

      expect(() => parse({...song(), 'artists': artists(20)}), returnsNormally);
      expect(
        () => parse({...song(), 'artists': artists(21)}),
        throwsFormatException,
      );
    });

    test('durationMs bounds and type', () {
      expect(() => parse({...song(), 'durationMs': 0}), returnsNormally);
      expect(() => parse({...song(), 'durationMs': -1}), throwsFormatException);
      expect(
        () => parse({...song(), 'durationMs': 1.5}),
        throwsFormatException,
      );
      expect(
        () => parse({...song(), 'durationMs': Item.maxDurationMs + 1}),
        throwsFormatException,
      );
    });
  });

  group('stream', () {
    final stream = {'type': 'endpoint', 'endpoint': 'tok'};

    for (final kind in ['song', 'video', 'episode']) {
      test('is allowed on $kind', () {
        expect(
          () => parse({'kind': kind, 'title': 'T', 'stream': stream}),
          returnsNormally,
        );
      });
    }

    for (final kind in ['podcast', 'album', 'playlist', 'artist']) {
      test('is rejected on $kind', () {
        expect(
          () => parse({'kind': kind, 'title': 'T', 'stream': stream}),
          throwsFormatException,
        );
      });
    }
  });

  group('nested errors name the full path', () {
    Matcher at(String text) => throwsA(
      isA<FormatException>().having(
        (e) => e.message,
        'message',
        contains(text),
      ),
    );

    test('artist name', () {
      expect(
        () => parse({
          ...song(),
          'artists': [{}],
        }),
        at('i.artists[0].name'),
      );
    });

    test('thumbnail URL', () {
      expect(
        () => parse({
          ...song(),
          'thumbnails': {'small': 'http://a.com'},
        }),
        at('i.thumbnails.small'),
      );
    });

    test('a null endpoint value is simply absent', () {
      expect(parse({...song(), 'play': null}).play, isNull);
    });
  });
}
