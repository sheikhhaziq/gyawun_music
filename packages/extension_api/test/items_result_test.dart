import 'package:extension_api/extension_api.dart';
import 'package:flutter_test/flutter_test.dart';

ItemsResult parse(Object? v) => ItemsResult.parse(v);

Map<String, Object?> item(String kind) => {'kind': kind, 'title': 'T'};

void main() {
  test('an empty object is a valid empty list', () {
    final r = parse({});

    expect(r.items, isEmpty);
    expect(r.continuation, isNull);
  });

  test('parses items and a continuation', () {
    final r = parse({
      'items': [item('song'), item('album')],
      'continuation': 'tok',
    });

    expect(r.items.map((i) => i.kind), [ItemKind.song, ItemKind.album]);
    expect(r.continuation!.toJson(), 'tok');
  });

  test('allows any item kind', () {
    for (final k in ItemKind.values) {
      expect(
        () => parse({
          'items': [item(k.name)],
        }),
        returnsNormally,
      );
    }
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

  test('errors name the full path', () {
    expect(
      () => parse({
        'items': [
          {'kind': 'song'},
        ],
      }),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('items.items[0].title'),
        ),
      ),
    );
  });

  test('rejects a non-object', () {
    expect(() => parse('x'), throwsFormatException);
  });
}
