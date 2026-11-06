import 'dart:convert';

import 'package:extension_repository/extension_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pub_semver/pub_semver.dart';

final repoA = Uri.parse('https://a.example.com/index.json');
final repoB = Uri.parse('https://b.example.com/index.json');

RepositoryIndex index(Map<String, ({String version, int api})> offers) =>
    RepositoryIndex.parse(
      jsonEncode({
        'schema': 1,
        'extensions': [
          for (final e in offers.entries)
            {
              'id': e.key,
              'name': 'N',
              'version': e.value.version,
              'apiVersion': e.value.api,
              'download': 'https://example.com/x.gmx',
              'sha256': 'a' * 64,
              'size': 1,
            },
        ],
      }),
    );

InstalledVersion installed(String version, {Uri? from}) => InstalledVersion(
  id: 'com.a.one',
  semver: Version.parse(version),
  repositoryUrl: from ?? repoA,
);

UpdateReport run(
  String installedVersion,
  String offered, {
  int api = 1,
  int supported = 1,
}) => findUpdates(
  [installed(installedVersion)],
  {
    repoA: index({'com.a.one': (version: offered, api: api)}),
  },
  supportedApiVersion: supported,
);

void main() {
  group('versions', () {
    for (final (from, to) in [
      ('1.0.0', '1.0.1'),
      ('1.2.0', '1.10.0'),
      ('1.9.9', '2.0.0'),
      ('1.0.0-beta.1', '1.0.0'),
      ('1.0.0-beta.1', '1.0.0-beta.2'),
    ]) {
      test('$from -> $to is an update', () {
        expect(run(from, to).updates, hasLength(1));
      });
    }

    for (final (from, to) in [
      ('1.0.0', '1.0.0'),
      ('1.0.1', '1.0.0'),
      ('2.0.0', '1.9.9'),
      ('1.10.0', '1.2.0'),
    ]) {
      test('$from -> $to is not offered', () {
        final r = run(from, to);

        expect(r.updates, isEmpty);
        expect(r.incompatible, isEmpty);
      });
    }
  });

  group('prereleases', () {
    test('a stable install is not pushed onto a beta', () {
      expect(run('1.0.0', '2.0.0-beta.1').updates, isEmpty);
    });

    test('a beta install is offered a newer beta', () {
      expect(run('1.0.0-beta.1', '1.0.0-beta.2').updates, hasLength(1));
    });

    test('a beta install is offered the next stable', () {
      expect(run('1.0.0-beta.1', '1.0.0').updates, hasLength(1));
    });
  });

  group('apiVersion', () {
    test('a supported apiVersion is an update', () {
      expect(run('1.0.0', '1.1.0', api: 2, supported: 2).updates, hasLength(1));
    });

    test('a newer apiVersion is reported as incompatible', () {
      final r = run('1.0.0', '1.1.0', api: 2, supported: 1);

      expect(r.updates, isEmpty);
      expect(r.incompatible.single.entry.version, '1.1.0');
    });
  });

  group('repositories', () {
    test('only the installed-from repository gives updates', () {
      final r = findUpdates(
        [installed('1.0.0')],
        {
          repoA: index({'com.a.one': (version: '1.0.0', api: 1)}),
          repoB: index({'com.a.one': (version: '2.0.0', api: 1)}),
        },
        supportedApiVersion: 1,
      );

      expect(r.updates, isEmpty);
      expect(r.otherSource.single.repositoryUrl, repoB);
      expect(r.otherSource.single.entry.version, '2.0.0');
    });

    test('an equal or older version elsewhere is ignored', () {
      final r = findUpdates(
        [installed('2.0.0')],
        {
          repoB: index({'com.a.one': (version: '2.0.0', api: 1)}),
        },
        supportedApiVersion: 1,
      );

      expect(r.otherSource, isEmpty);
    });

    test('an incompatible version elsewhere is not reported', () {
      final r = findUpdates(
        [installed('1.0.0')],
        {
          repoB: index({'com.a.one': (version: '2.0.0', api: 5)}),
        },
        supportedApiVersion: 1,
      );

      expect(r.otherSource, isEmpty);
    });

    test('a repository that was not fetched is skipped', () {
      final r = findUpdates([installed('1.0.0')], {}, supportedApiVersion: 1);

      expect(r.updates, isEmpty);
    });

    test('an extension missing from its repository has no update', () {
      final r = findUpdates(
        [installed('1.0.0')],
        {
          repoA: index({'com.a.other': (version: '9.0.0', api: 1)}),
        },
        supportedApiVersion: 1,
      );

      expect(r.updates, isEmpty);
    });

    test('both an own update and another source can be reported', () {
      final r = findUpdates(
        [installed('1.0.0')],
        {
          repoA: index({'com.a.one': (version: '1.1.0', api: 1)}),
          repoB: index({'com.a.one': (version: '3.0.0', api: 1)}),
        },
        supportedApiVersion: 1,
      );

      expect(r.updates.single.entry.version, '1.1.0');
      expect(r.otherSource.single.entry.version, '3.0.0');
    });
  });

  test('handles several installed extensions', () {
    final r = findUpdates(
      [
        InstalledVersion(
          id: 'com.a.one',
          semver: Version(1, 0, 0),
          repositoryUrl: repoA,
        ),
        InstalledVersion(
          id: 'com.a.two',
          semver: Version(1, 0, 0),
          repositoryUrl: repoA,
        ),
      ],
      {
        repoA: index({
          'com.a.one': (version: '1.1.0', api: 1),
          'com.a.two': (version: '1.0.0', api: 1),
        }),
      },
      supportedApiVersion: 1,
    );

    expect(r.updates.map((u) => u.installed.id), ['com.a.one']);
  });

  test('results are unmodifiable', () {
    expect(() => run('1.0.0', '1.1.0').updates.clear(), throwsUnsupportedError);
  });

  test('no installed extensions gives an empty report', () {
    final r = findUpdates([], {}, supportedApiVersion: 1);

    expect(r.updates, isEmpty);
    expect(r.incompatible, isEmpty);
    expect(r.otherSource, isEmpty);
  });
}
