import 'package:extension_api/extension_api.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher failsWith(String text) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(text)),
);

void main() {
  JsonObject obj(Object? v) => JsonObject.of(v, 'x');

  group('of', () {
    test('accepts an object', () {
      expect(obj({}).path, 'x');
    });

    for (final bad in [null, 5, 'text', <Object?>[], true]) {
      test('rejects $bad', () {
        expect(() => obj(bad), throwsFormatException);
      });
    }

    test('the error names the path', () {
      expect(
        () => JsonObject.of(5, 'browse.header'),
        failsWith('browse.header'),
      );
    });
  });

  group('string', () {
    test('returns a valid string', () {
      expect(obj({'a': 'hi'}).string('a'), 'hi');
    });

    for (final bad in [null, 5, true, '', '   ']) {
      test('rejects $bad', () {
        expect(() => obj({'a': bad}).string('a'), throwsFormatException);
      });
    }

    test('does not trim what it returns', () {
      expect(obj({'a': ' hi '}).string('a'), ' hi ');
    });

    test('enforces the max length at the boundary', () {
      expect(obj({'a': 'a' * 5}).string('a', max: 5), 'aaaaa');
      expect(
        () => obj({'a': 'a' * 6}).string('a', max: 5),
        throwsFormatException,
      );
    });

    test('the error names the path and key', () {
      expect(() => obj({}).string('title'), failsWith('x.title'));
    });
  });

  group('optionalString', () {
    test('is null when absent or null', () {
      expect(obj({}).optionalString('a'), isNull);
      expect(obj({'a': null}).optionalString('a'), isNull);
    });

    test('is validated when present', () {
      expect(obj({'a': 'ok'}).optionalString('a'), 'ok');
      expect(() => obj({'a': 5}).optionalString('a'), throwsFormatException);
      expect(() => obj({'a': ''}).optionalString('a'), throwsFormatException);
    });
  });

  group('object and optionalObject', () {
    test('object requires the key', () {
      expect(() => obj({}).object('o'), failsWith('x.o is required'));
    });

    test('object returns a child with an extended path', () {
      expect(obj({'o': {}}).object('o').path, 'x.o');
    });

    test('object rejects a non-object', () {
      expect(() => obj({'o': 5}).object('o'), failsWith('x.o'));
    });

    test('optionalObject is null when absent', () {
      expect(obj({}).optionalObject('o'), isNull);
    });

    test('optionalObject rejects a non-object when present', () {
      expect(() => obj({'o': []}).optionalObject('o'), throwsFormatException);
    });

    test('nested paths accumulate', () {
      final child = obj({
        'a': {'b': {}},
      }).object('a').object('b');

      expect(child.path, 'x.a.b');
    });
  });

  group('objects', () {
    test('a missing list is empty', () {
      expect(obj({}).objects('l', max: 3), isEmpty);
      expect(obj({'l': null}).objects('l', max: 3), isEmpty);
    });

    test('returns children with indexed paths', () {
      final list = obj({
        'l': [{}, {}],
      }).objects('l', max: 3);

      expect(list.map((o) => o.path), ['x.l[0]', 'x.l[1]']);
    });

    test('rejects a non-list', () {
      expect(() => obj({'l': 'x'}).objects('l', max: 3), failsWith('x.l'));
    });

    test('rejects a non-object entry and names its index', () {
      expect(
        () => obj({
          'l': [{}, 5],
        }).objects('l', max: 3),
        failsWith('x.l[1]'),
      );
    });

    test('accepts exactly max entries', () {
      expect(
        obj({
          'l': [{}, {}, {}],
        }).objects('l', max: 3),
        hasLength(3),
      );
    });

    test('rejects more than max entries instead of truncating', () {
      expect(
        () => obj({
          'l': [{}, {}, {}, {}],
        }).objects('l', max: 3),
        failsWith('at most 3'),
      );
    });
  });

  group('raw and pathOf', () {
    test('raw returns the value unchanged', () {
      expect(
        obj({
          'a': [1, 2],
        }).raw('a'),
        [1, 2],
      );
      expect(obj({}).raw('a'), isNull);
    });

    test('pathOf builds a child path', () {
      expect(obj({}).pathOf('k'), 'x.k');
    });
  });
}
