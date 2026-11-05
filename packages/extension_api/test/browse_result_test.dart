import 'package:extension_api/extension_api.dart';
import 'package:flutter_test/flutter_test.dart';

BrowseResult parse(Object? v) => BrowseResult.parse(v);

Map<String, Object?> item([String t = 'T']) => {'kind': 'song', 'title': t};
Map<String, Object?> section(int items) => {
  'items': [for (var i = 0; i < items; i++) item()],
};

Matcher at(String text) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(text)),
);

void main() {
  test('an empty object is a valid empty screen', () {
    final r = parse({});

    expect(r.header, isNull);
    expect(r.chips, isEmpty);
    expect(r.sections, isEmpty);
    expect(r.continuation, isNull);
  });

  test('parses every part', () {
    final r = parse({
      'header': {'title': 'Home'},
      'chips': [
        {'text': 'Recent', 'endpoint': 'e'},
      ],
      'sections': [section(2)],
      'continuation': {'page': 2},
    });

    expect(r.header!.title, 'Home');
    expect(r.chips.single.text, 'Recent');
    expect(r.sections.single.items, hasLength(2));
    expect(r.continuation!.toJson(), {'page': 2});
  });

  test('rejects a non-object', () {
    expect(() => parse([]), throwsFormatException);
    expect(() => parse(null), throwsFormatException);
  });

  test('collections are unmodifiable', () {
    final r = parse({
      'sections': [section(1)],
    });

    expect(() => r.sections.clear(), throwsUnsupportedError);
    expect(() => r.chips.clear(), throwsUnsupportedError);
  });

  group('limits', () {
    test('sections: 100 ok, 101 rejected', () {
      expect(
        () => parse({
          'sections': [for (var i = 0; i < 100; i++) {}],
        }),
        returnsNormally,
      );
      expect(
        () => parse({
          'sections': [for (var i = 0; i < 101; i++) {}],
        }),
        throwsFormatException,
      );
    });

    test('chips: 50 ok, 51 rejected', () {
      List<Object?> n(int c) => [
        for (var i = 0; i < c; i++) {'text': 't', 'endpoint': 1},
      ];

      expect(() => parse({'chips': n(50)}), returnsNormally);
      expect(() => parse({'chips': n(51)}), throwsFormatException);
    });

    test('total items: 2000 ok, 2001 rejected', () {
      final ok = [for (var i = 0; i < 10; i++) section(200)];
      expect(() => parse({'sections': ok}), returnsNormally);

      final tooMany = [...ok.take(9), section(200), section(1)];
      expect(() => parse({'sections': tooMany}), at('2001 items in total'));
    });
  });

  group('errors name the full path', () {
    test('a bad item in a section', () {
      expect(
        () => parse({
          'sections': [
            {
              'items': [
                {'kind': 'song'},
              ],
            },
          ],
        }),
        at('browse.sections[0].items[0].title'),
      );
    });

    test('a bad chip', () {
      expect(
        () => parse({
          'chips': [
            {'text': 'x'},
          ],
        }),
        at('browse.chips[0].endpoint'),
      );
    });

    test('a bad header', () {
      expect(() => parse({'header': {}}), at('browse.header.title'));
    });

    test('a null continuation is absent', () {
      expect(parse({'continuation': null}).continuation, isNull);
    });
  });

  test('a custom path is used in errors', () {
    expect(() => BrowseResult.parse([], 'home'), at('home'));
  });
}
