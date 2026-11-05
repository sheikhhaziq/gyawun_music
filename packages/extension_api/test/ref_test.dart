import 'package:extension_api/extension_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ItemKind', () {
    test('parses every kind', () {
      for (final kind in ItemKind.values) {
        expect(ItemKind.parse(kind.name, 'k'), kind);
      }
    });

    test('only song, video and episode are playable', () {
      expect(ItemKind.values.where((k) => k.isPlayable), [
        ItemKind.song,
        ItemKind.video,
        ItemKind.episode,
      ]);
    });

    for (final bad in ['Song', 'track', '', 'SONG']) {
      test('rejects "$bad"', () {
        expect(() => ItemKind.parse(bad, 'k'), throwsFormatException);
      });
    }
  });

  group('Ref', () {
    Ref parse(Object? v) => Ref.parse(JsonObject.of(v, 'r'));

    test('parses a name only', () {
      final r = parse({'name': 'Artist'});

      expect(r.name, 'Artist');
      expect(r.browse, isNull);
    });

    test('keeps the browse endpoint as given', () {
      final r = parse({
        'name': 'A',
        'browse': {'id': 'x'},
      });

      expect(r.browse!.toJson(), {'id': 'x'});
    });

    test('rejects a missing or blank name', () {
      expect(() => parse({}), throwsFormatException);
      expect(() => parse({'name': ' '}), throwsFormatException);
    });

    test('rejects a name over 200 characters', () {
      expect(() => parse({'name': 'a' * 201}), throwsFormatException);
    });

    test('parseOptional is null when absent', () {
      expect(Ref.parseOptional(JsonObject.of({}, 'p'), 'album'), isNull);
    });
  });
}
