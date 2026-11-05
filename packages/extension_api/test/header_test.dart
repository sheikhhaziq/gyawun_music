import 'package:extension_api/extension_api.dart';
import 'package:flutter_test/flutter_test.dart';

Header parse(Map<String, Object?> v) => Header.parse(JsonObject.of(v, 'h'));

Map<String, Object?> action([String label = 'Play']) => {
  'label': label,
  'action': {'type': 'play', 'endpoint': 'q'},
};

Matcher at(String text) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(text)),
);

void main() {
  test('parses the minimum', () {
    final h = parse({'title': 'Artist'});

    expect(h.title, 'Artist');
    expect(h.description, isNull);
    expect(h.thumbnails, isNull);
    expect(h.actions, isEmpty);
  });

  test('parses every field', () {
    final h = parse({
      'title': 'Artist',
      'description': 'About',
      'thumbnails': {'large': 'https://a.com/l.jpg'},
      'actions': [
        action('Play'),
        {
          'label': 'Browse',
          'action': {'type': 'browse', 'endpoint': 'e'},
        },
      ],
    });

    expect(h.description, 'About');
    expect(h.thumbnails!.large, isNotNull);
    expect(h.actions.map((a) => a.label), ['Play', 'Browse']);
    expect(h.actions[0].action, isA<PlayAction>());
    expect(h.actions[1].action, isA<BrowseAction>());
  });

  test('requires a title', () {
    expect(() => parse({}), throwsFormatException);
    expect(() => parse({'title': ''}), throwsFormatException);
  });

  group('limits', () {
    test('description up to 1000 characters', () {
      expect(
        () => parse({'title': 'a', 'description': 'a' * 1000}),
        returnsNormally,
      );
      expect(
        () => parse({'title': 'a', 'description': 'a' * 1001}),
        throwsFormatException,
      );
    });

    test('at most 5 actions', () {
      List<Object?> n(int c) => [for (var i = 0; i < c; i++) action('a$i')];

      expect(() => parse({'title': 'a', 'actions': n(5)}), returnsNormally);
      expect(
        () => parse({'title': 'a', 'actions': n(6)}),
        throwsFormatException,
      );
    });

    test('action label up to 50 characters', () {
      expect(
        () => parse({
          'title': 'a',
          'actions': [action('a' * 51)],
        }),
        throwsFormatException,
      );
    });
  });

  group('errors name the full path', () {
    test('an action without an action object', () {
      expect(
        () => parse({
          'title': 'a',
          'actions': [
            {'label': 'x'},
          ],
        }),
        at('h.actions[0].action'),
      );
    });

    test('an action with an unknown type', () {
      expect(
        () => parse({
          'title': 'a',
          'actions': [
            {
              'label': 'x',
              'action': {'type': 'z', 'endpoint': 1},
            },
          ],
        }),
        at('h.actions[0].action.type'),
      );
    });

    test('a bad thumbnail', () {
      expect(
        () => parse({
          'title': 'a',
          'thumbnails': {'small': 'http://a.com'},
        }),
        at('h.thumbnails.small'),
      );
    });
  });

  test('parseOptional is null when absent', () {
    expect(Header.parseOptional(JsonObject.of({}, 'p'), 'header'), isNull);
  });
}
