import 'package:extension_api/extension_api.dart';
import 'package:extension_repository/extension_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final _hash = 'a' * 64;

Map<String, Object?> valid() => {
  'id': 'com.example.music',
  'name': 'Example',
  'version': '1.2.0',
  'apiVersion': 1,
  'download': 'https://example.com/example.gmx',
  'sha256': _hash,
  'size': 1000,
};

RepositoryEntry parse(Map<String, Object?> v) =>
    RepositoryEntry.parse(JsonObject.of(v, 'e'));

Matcher failsWith(String text) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(text)),
);

void main() {
  test('parses the required fields', () {
    final e = parse(valid());

    expect(e.id, 'com.example.music');
    expect(e.version, '1.2.0');
    expect(e.semver > parse({...valid(), 'version': '1.10.0'}).semver, isFalse);
    expect(e.apiVersion, 1);
    expect(e.download, Uri.parse('https://example.com/example.gmx'));
    expect(e.sha256, _hash);
    expect(e.size, 1000);
    expect(e.description, isNull);
    expect(e.icon, isNull);
  });

  test('parses the optional fields', () {
    final e = parse({
      ...valid(),
      'description': 'Browse',
      'author': 'Jane',
      'icon': 'https://example.com/i.png',
    });

    expect(e.description, 'Browse');
    expect(e.author, 'Jane');
    expect(e.icon, Uri.parse('https://example.com/i.png'));
  });

  test('ignores unknown keys', () {
    expect(() => parse({...valid(), 'future': 1}), returnsNormally);
  });

  group('required fields', () {
    for (final key in [
      'id',
      'name',
      'version',
      'apiVersion',
      'download',
      'sha256',
      'size',
    ]) {
      test('$key is required', () {
        expect(() => parse({...valid()}..remove(key)), failsWith('e.$key'));
      });
    }
  });

  group('id and version use the gmx rules', () {
    for (final bad in ['music', 'Com.Example', 'com.example\n']) {
      test('rejects id "${bad.replaceAll('\n', r'\n')}"', () {
        expect(() => parse({...valid(), 'id': bad}), failsWith('e.id'));
      });
    }

    for (final bad in ['1.0', 'v1.0.0', '1.0.0\n']) {
      test('rejects version "${bad.replaceAll('\n', r'\n')}"', () {
        expect(
          () => parse({...valid(), 'version': bad}),
          failsWith('e.version'),
        );
      });
    }
  });

  group('sha256', () {
    for (final bad in ['a' * 63, 'a' * 65, 'A' * 64, 'g' * 64, '']) {
      test('rejects "$bad"', () {
        expect(() => parse({...valid(), 'sha256': bad}), throwsFormatException);
      });
    }
  });

  group('size', () {
    test('accepts the bounds', () {
      expect(parse({...valid(), 'size': 1}).size, 1);
      expect(
        parse({...valid(), 'size': RepositoryEntry.maxSize}).size,
        RepositoryEntry.maxSize,
      );
    });

    for (final bad in [0, -1, RepositoryEntry.maxSize + 1, 1.5, '10']) {
      test('rejects $bad', () {
        expect(() => parse({...valid(), 'size': bad}), throwsFormatException);
      });
    }
  });

  group('apiVersion', () {
    for (final bad in [0, -1, 1.5, '1']) {
      test('rejects $bad', () {
        expect(
          () => parse({...valid(), 'apiVersion': bad}),
          throwsFormatException,
        );
      });
    }
  });

  group('urls must be https', () {
    for (final bad in [
      'http://a.com/x.gmx',
      'file:///x',
      'not a url',
      'https://u:p@a.com/x',
    ]) {
      test('rejects download $bad', () {
        expect(
          () => parse({...valid(), 'download': bad}),
          failsWith('e.download'),
        );
      });
    }

    test('rejects an http icon', () {
      expect(
        () => parse({...valid(), 'icon': 'http://a.com/i.png'}),
        failsWith('e.icon'),
      );
    });
  });

  test('description: 200 characters ok, 201 rejected', () {
    expect(
      () => parse({...valid(), 'description': 'a' * 200}),
      returnsNormally,
    );
    expect(
      () => parse({...valid(), 'description': 'a' * 201}),
      throwsFormatException,
    );
  });

  test('rejects a name over 60 characters', () {
    expect(() => parse({...valid(), 'name': 'a' * 61}), throwsFormatException);
  });
}
