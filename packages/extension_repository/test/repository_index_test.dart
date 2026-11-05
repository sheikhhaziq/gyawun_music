import 'dart:convert';

import 'package:extension_repository/extension_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> entry([String id = 'com.example.music']) => {
  'id': id,
  'name': 'Example',
  'version': '1.0.0',
  'apiVersion': 1,
  'download': 'https://example.com/a.gmx',
  'sha256': 'a' * 64,
  'size': 100,
};

RepositoryIndex parse(Object? v) => RepositoryIndex.parse(jsonEncode(v));

Matcher failsWith(String text) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(text)),
);

void main() {
  test('parses a repository', () {
    final i = parse({
      'schema': 1,
      'name': 'Official',
      'extensions': [entry('com.a.one'), entry('com.a.two')],
    });

    expect(i.name, 'Official');
    expect(i.entries.map((e) => e.id), ['com.a.one', 'com.a.two']);
    expect(i.problems, isEmpty);
  });

  test('an empty repository is valid', () {
    expect(parse({'schema': 1, 'extensions': []}).entries, isEmpty);
  });

  test('find returns an entry by id', () {
    final i = parse({
      'schema': 1,
      'extensions': [entry('com.a.one')],
    });

    expect(i.find('com.a.one')!.id, 'com.a.one');
    expect(i.find('com.a.none'), isNull);
  });

  test('ignores unknown top-level keys', () {
    expect(
      () => parse({'schema': 1, 'extensions': [], 'revoked': []}),
      returnsNormally,
    );
  });

  group('whole-file errors', () {
    test('invalid JSON', () {
      expect(() => RepositoryIndex.parse('{nope'), throwsFormatException);
    });

    test('not an object', () {
      expect(() => parse([]), throwsFormatException);
    });

    test('missing or unsupported schema', () {
      expect(
        () => parse({'extensions': []}),
        failsWith('Unsupported repository schema'),
      );
      expect(
        () => parse({'schema': 2, 'extensions': []}),
        failsWith('schema: 2'),
      );
    });

    test('extensions missing or not a list', () {
      expect(() => parse({'schema': 1}), failsWith('index.extensions'));
      expect(
        () => parse({'schema': 1, 'extensions': 'x'}),
        failsWith('index.extensions'),
      );
    });

    test('an entry that is not an object', () {
      expect(
        () => parse({
          'schema': 1,
          'extensions': [5],
        }),
        failsWith('index.extensions[0]'),
      );
    });

    test('too many entries', () {
      List<Object?> n(int c) => [
        for (var i = 0; i < c; i++)
          entry('com.a.n$i'.replaceAll(RegExp(r'\d'), 'x')),
      ];

      expect(
        () => parse({'schema': 1, 'extensions': n(1001)}),
        failsWith('at most 1000'),
      );
    });

    test('file too large', () {
      final big = jsonEncode({
        'schema': 1,
        'extensions': [],
        'pad': 'a' * (2 << 20),
      });

      expect(() => RepositoryIndex.parse(big), failsWith('too large'));
    });
  });

  group('bad entries are skipped and reported', () {
    test('keeps the valid entries around a bad one', () {
      final i = parse({
        'schema': 1,
        'extensions': [
          entry('com.a.one'),
          {...entry('com.a.two'), 'sha256': 'bad'},
          entry('com.a.three'),
        ],
      });

      expect(i.entries.map((e) => e.id), ['com.a.one', 'com.a.three']);
      expect(i.problems, hasLength(1));
      expect(i.problems.single, contains('index.extensions[1].sha256'));
    });

    test('the first of duplicate ids wins', () {
      final i = parse({
        'schema': 1,
        'extensions': [
          {...entry('com.a.one'), 'version': '1.0.0'},
          {...entry('com.a.one'), 'version': '9.0.0'},
        ],
      });

      expect(i.entries.single.version, '1.0.0');
      expect(i.problems.single, contains('duplicates id com.a.one'));
    });

    test('an http download is skipped, not fatal', () {
      final i = parse({
        'schema': 1,
        'extensions': [
          {...entry(), 'download': 'http://a.com/x.gmx'},
        ],
      });

      expect(i.entries, isEmpty);
      expect(i.problems.single, contains('download'));
    });
  });

  test('entries and problems are unmodifiable', () {
    final i = parse({'schema': 1, 'extensions': []});

    expect(() => i.entries.clear(), throwsUnsupportedError);
    expect(() => i.problems.clear(), throwsUnsupportedError);
  });
}
