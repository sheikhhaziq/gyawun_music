import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gmx/gmx.dart';

Map<String, Object?> valid() => {
  'id': 'com.example.music',
  'name': 'Example',
  'version': '1.0.0',
  'apiVersion': 1,
};

GmxMetadata parse(Map<String, Object?> json) => GmxMetadata.fromJson(json);

void main() {
  group('valid metadata', () {
    test('parses the required fields', () {
      final m = parse(valid());

      expect(m.id, 'com.example.music');
      expect(m.name, 'Example');
      expect(m.version, '1.0.0');
      expect(m.apiVersion, 1);
    });

    test('optional fields default sensibly', () {
      final m = parse(valid());

      expect(m.description, isNull);
      expect(m.author, isNull);
      expect(m.permissions.storage, isFalse);
      expect(m.permissions.log, isTrue);
      expect(m.permissions.network, isFalse);
      expect(m.permissions.granted, {'log'});
    });

    test('parses every field', () {
      final m = parse({
        ...valid(),
        'description': 'Browse music',
        'author': 'Jane',
        'permissions': {
          'storage': true,
          'log': false,
          'network': {
            'domains': ['api.example.com', '*.cdn.example.com'],
          },
        },
      });

      expect(m.description, 'Browse music');
      expect(m.author, 'Jane');
      expect(m.permissions.storage, isTrue);
      expect(m.permissions.log, isFalse);
      expect(m.permissions.networkDomains, [
        'api.example.com',
        '*.cdn.example.com',
      ]);
      expect(m.permissions.granted, {'storage', 'http'});
    });

    test('trims display strings', () {
      final m = parse({...valid(), 'name': '  Example  '});

      expect(m.name, 'Example');
    });

    test('ignores unknown top-level keys', () {
      expect(() => parse({...valid(), 'futureField': 1}), returnsNormally);
    });
  });

  group('parse (text)', () {
    test('parses JSON text', () {
      final m = GmxMetadata.parse(jsonEncode(valid()));

      expect(m.id, 'com.example.music');
    });

    test('rejects invalid JSON', () {
      expect(() => GmxMetadata.parse('{nope'), throwsFormatException);
    });

    test('rejects JSON that is not an object', () {
      expect(() => GmxMetadata.parse('[1, 2]'), throwsFormatException);
      expect(() => GmxMetadata.parse('"text"'), throwsFormatException);
      expect(() => GmxMetadata.parse('null'), throwsFormatException);
    });

    test('rejects an oversized file', () {
      final big = jsonEncode({...valid(), 'description': 'a' * 70000});

      expect(() => GmxMetadata.parse(big), throwsFormatException);
    });

    test('treats a 1.0 apiVersion as invalid', () {
      expect(
        () => GmxMetadata.parse(
          '{"id":"com.a.b","name":"x","version":"1.0.0","apiVersion":1.0}',
        ),
        throwsFormatException,
      );
    });
  });

  group('id', () {
    for (final id in ['com.example.music', 'a.b', 'org.my_app.ext2']) {
      test('accepts $id', () {
        expect(() => parse({...valid(), 'id': id}), returnsNormally);
      });
    }

    for (final id in [
      '',
      'music',
      'Com.Example',
      'com..example',
      'com.example.',
      '.com.example',
      '1com.example',
      'com.exa mple',
      'com.example/music',
      'com.example.music\n',
      ' com.example.music',
      'com-example.music',
    ]) {
      test('rejects "${id.replaceAll('\n', r'\n')}"', () {
        expect(() => parse({...valid(), 'id': id}), throwsFormatException);
      });
    }

    test('rejects a missing id', () {
      expect(() => parse({...valid()}..remove('id')), throwsFormatException);
    });

    test('rejects a non-string id', () {
      expect(() => parse({...valid(), 'id': 5}), throwsFormatException);
    });

    test('rejects an id over 100 characters', () {
      final id = 'a.${'b' * 100}';

      expect(() => parse({...valid(), 'id': id}), throwsFormatException);
    });
  });

  group('version', () {
    for (final v in ['0.0.1', '1.2.3', '10.20.30', '1.0.0-beta.1', '1.0.0+5']) {
      test('accepts $v', () {
        expect(() => parse({...valid(), 'version': v}), returnsNormally);
      });
    }

    for (final v in ['1', '1.0', '01.0.0', '1.0.0.0', 'v1.0.0', '1.a.0', '']) {
      test('rejects "$v"', () {
        expect(() => parse({...valid(), 'version': v}), throwsFormatException);
      });
    }

    test('rejects a missing version', () {
      expect(
        () => parse({...valid()}..remove('version')),
        throwsFormatException,
      );
    });

    test('rejects surrounding whitespace', () {
      expect(
        () => parse({...valid(), 'version': ' 1.0.0'}),
        throwsFormatException,
      );
      expect(
        () => parse({...valid(), 'version': '1.0.0\n'}),
        throwsFormatException,
      );
    });

    test('keeps the version string as written', () {
      expect(parse({...valid(), 'version': '1.0.0+5'}).version, '1.0.0+5');
    });

    test('exposes a comparable semver', () {
      final a = parse({...valid(), 'version': '1.2.0'}).semver;
      final b = parse({...valid(), 'version': '1.10.0'}).semver;

      expect(b > a, isTrue); // numeric, not string, ordering
    });

    test('a prerelease is lower than its release', () {
      final pre = parse({...valid(), 'version': '1.0.0-beta.1'}).semver;
      final rel = parse({...valid(), 'version': '1.0.0'}).semver;

      expect(pre < rel, isTrue);
    });
  });

  group('apiVersion', () {
    test('accepts a positive integer', () {
      expect(parse({...valid(), 'apiVersion': 3}).apiVersion, 3);
    });

    for (final v in [0, -1, 1.5, '1', null, true]) {
      test('rejects $v', () {
        expect(
          () => parse({...valid(), 'apiVersion': v}),
          throwsFormatException,
        );
      });
    }
  });

  group('name, description, author', () {
    test('rejects a blank name', () {
      expect(() => parse({...valid(), 'name': '  '}), throwsFormatException);
    });

    test('rejects a missing name', () {
      expect(() => parse({...valid()}..remove('name')), throwsFormatException);
    });

    test('rejects a name over 60 characters', () {
      expect(
        () => parse({...valid(), 'name': 'a' * 61}),
        throwsFormatException,
      );
    });

    test('accepts a name exactly at the limit', () {
      expect(() => parse({...valid(), 'name': 'a' * 60}), returnsNormally);
    });

    test('rejects a description over 500 characters', () {
      expect(
        () => parse({...valid(), 'description': 'a' * 501}),
        throwsFormatException,
      );
    });

    test('rejects a non-string author', () {
      expect(() => parse({...valid(), 'author': 5}), throwsFormatException);
    });
  });

  group('permissions', () {
    Map<String, Object?> withPermissions(Object? p) => {
      ...valid(),
      'permissions': p,
    };

    test('rejects permissions that is not an object', () {
      expect(() => parse(withPermissions([])), throwsFormatException);
    });

    test('rejects an unknown permission', () {
      expect(
        () => parse(withPermissions({'netwrok': true})),
        throwsFormatException,
      );
    });

    test('rejects a non-boolean storage or log', () {
      expect(
        () => parse(withPermissions({'storage': 'yes'})),
        throwsFormatException,
      );
      expect(() => parse(withPermissions({'log': 1})), throwsFormatException);
    });

    test('rejects network that is not an object', () {
      expect(
        () => parse(withPermissions({'network': true})),
        throwsFormatException,
      );
    });

    test('rejects network without domains', () {
      expect(
        () => parse(withPermissions({'network': {}})),
        throwsFormatException,
      );
    });

    test('rejects an empty domain list', () {
      expect(
        () => parse(
          withPermissions({
            'network': {'domains': []},
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects unknown network options', () {
      expect(
        () => parse(
          withPermissions({
            'network': {
              'domains': ['api.example.com'],
              'allowHttp': true,
            },
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects too many domains', () {
      final domains = [for (var i = 0; i < 51; i++) 'd$i.example.com'];

      expect(
        () => parse(
          withPermissions({
            'network': {'domains': domains},
          }),
        ),
        throwsFormatException,
      );
    });

    group('domains', () {
      List<String> domainsOf(List<Object?> domains) => parse(
        withPermissions({
          'network': {'domains': domains},
        }),
      ).permissions.networkDomains;

      for (final d in [
        'api.example.com',
        '*.example.com',
        'a.b.c.example.co.uk',
        'my-api.example.com',
        'xn--bcher-kva.example',
      ]) {
        test('accepts $d', () {
          expect(domainsOf([d]), [d]);
        });
      }

      for (final d in [
        'localhost',
        'example',
        '*',
        '*.com.',
        '*example.com',
        '**.example.com',
        'example.*',
        'https://example.com',
        'example.com/path',
        'example.com:443',
        'user@example.com',
        '127.0.0.1',
        '192.168.1.10',
        '[::1]',
        '-bad.example.com',
        'bad-.example.com',
        'exa mple.com',
        'example.c',
        'example.123',
        '',
      ]) {
        test('rejects "$d"', () {
          expect(() => domainsOf([d]), throwsFormatException);
        });
      }

      test('rejects a non-string entry', () {
        expect(() => domainsOf([5]), throwsFormatException);
        expect(() => domainsOf([null]), throwsFormatException);
      });

      test('lowercases and trims', () {
        expect(domainsOf(['  API.Example.COM ']), ['api.example.com']);
      });

      test('removes duplicates, keeping order', () {
        expect(domainsOf(['b.example.com', 'a.example.com', 'B.example.com']), [
          'b.example.com',
          'a.example.com',
        ]);
      });
    });

    group('granted', () {
      test('storage only adds storage', () {
        final p = parse(withPermissions({'storage': true, 'log': false}))
            .permissions;

        expect(p.granted, {'storage'});
      });

      test('network adds http', () {
        final p = parse(
          withPermissions({
            'network': {
              'domains': ['api.example.com'],
            },
          }),
        ).permissions;

        expect(p.granted, {'log', 'http'});
      });

      test('everything off grants nothing', () {
        final p = parse(withPermissions({'log': false})).permissions;

        expect(p.granted, isEmpty);
      });
    });
  });

  group('GmxFiles', () {
    test('required files are metadata.json and extension.js', () {
      expect(GmxFiles.required, {'metadata.json', 'extension.js'});
    });

    test('allowed is required plus optional', () {
      expect(GmxFiles.allowed, {
        'metadata.json',
        'extension.js',
        'icon.png',
        'README.md',
        'CHANGELOG.md',
        'LICENSE',
      });
    });

    group('validators', () {
      test('isValidId matches the rules used by parsing', () {
        expect(GmxMetadata.isValidId('com.example.music'), isTrue);
        for (final bad in [
          'music',
          'Com.Example',
          'com.example\n',
          ' a.b',
          '',
        ]) {
          expect(GmxMetadata.isValidId(bad), isFalse, reason: bad);
        }
      });

      test('isValidVersion matches the rules used by parsing', () {
        expect(GmxMetadata.isValidVersion('1.0.0-beta.1'), isTrue);
        for (final bad in ['1.0', '01.0.0', 'v1.0.0', '1.0.0\n', '']) {
          expect(GmxMetadata.isValidVersion(bad), isFalse, reason: bad);
        }
      });
    });

    test('required and optional do not overlap', () {
      expect(GmxFiles.required.intersection(GmxFiles.optional), isEmpty);
    });
  });
}
