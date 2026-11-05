import 'package:extension_api/extension_api.dart';
import 'package:flutter_test/flutter_test.dart';

Section parse(Map<String, Object?> v) => Section.parse(JsonObject.of(v, 's'));

Map<String, Object?> item([String title = 'T']) => {
  'kind': 'song',
  'title': title,
};

void main() {
  test('parses an empty section with defaults', () {
    final s = parse({});

    expect(s.title, isNull);
    expect(s.style, SectionStyle.horizontal);
    expect(s.action, isNull);
    expect(s.items, isEmpty);
  });

  test('parses every field', () {
    final s = parse({
      'title': 'Trending',
      'style': 'carousel',
      'action': {'type': 'play', 'endpoint': 'q'},
      'items': [item('a'), item('b')],
    });

    expect(s.title, 'Trending');
    expect(s.style, SectionStyle.carousel);
    expect(s.action, isA<PlayAction>());
    expect(s.items.map((i) => i.title), ['a', 'b']);
  });

  test('an unknown style falls back to horizontal', () {
    expect(parse({'style': 'grid'}).style, SectionStyle.horizontal);
  });

  test('a non-string style is an error', () {
    expect(() => parse({'style': 5}), throwsFormatException);
  });

  test('items are unmodifiable', () {
    expect(
      () => parse({
        'items': [item()],
      }).items.add(Item.parse(JsonObject.of(item(), 'x'))),
      throwsUnsupportedError,
    );
  });

  group('limits', () {
    List<Object?> n(int c) => [for (var i = 0; i < c; i++) item()];

    test('accepts 200 items', () {
      expect(parse({'items': n(200)}).items, hasLength(200));
    });

    test('rejects 201 items', () {
      expect(() => parse({'items': n(201)}), throwsFormatException);
    });

    test('rejects a title over 200 characters', () {
      expect(() => parse({'title': 'a' * 201}), throwsFormatException);
    });
  });

  group('errors name the full path', () {
    Matcher at(String text) => throwsA(
      isA<FormatException>().having(
        (e) => e.message,
        'message',
        contains(text),
      ),
    );

    test('a bad item', () {
      expect(
        () => parse({
          'items': [
            item(),
            {'kind': 'song'},
          ],
        }),
        at('s.items[1].title'),
      );
    });

    test('a bad action', () {
      expect(
        () => parse({
          'action': {'type': 'x', 'endpoint': 1},
        }),
        at('s.action.type'),
      );
    });

    test('items that are not a list', () {
      expect(() => parse({'items': 'x'}), at('s.items'));
    });
  });
}
