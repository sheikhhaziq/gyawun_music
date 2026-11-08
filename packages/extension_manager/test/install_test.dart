import 'dart:typed_data';

import 'package:extension_manager/extension_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import 'rig.dart';

Matcher installFails(String text) => throwsA(
  isA<InstallException>().having((e) => e.message, 'message', contains(text)),
);

const net = {
  'network': {
    'domains': ['api.example.com'],
  },
};

void main() {
  group('fresh install', () {
    test('saves the archive and a disabled record', () async {
      final rig = Rig();
      final bytes = gmx();

      final record = await rig.install(bytes);

      expect(record!.id, 'com.example.music');
      expect(record.version, '1.0.0');
      expect(record.repositoryUrl, repoA);
      expect(record.enabled, isFalse);
      expect(record.installedAt, DateTime.utc(2025, 1, 1));
      expect(await rig.files.read('com.example.music'), bytes);
      expect(await rig.store.all(), [record]);
    });

    test('asks the user with the archive metadata', () async {
      final rig = Rig();

      await rig.install(gmx(permissions: {'storage': true, ...net}));

      final prompt = rig.prompts.single;
      expect(prompt.isUpdate, isFalse);
      expect(prompt.metadata.permissions.storage, isTrue);
      expect(prompt.metadata.permissions.networkDomains, ['api.example.com']);
    });

    test('declining writes nothing and returns null', () async {
      final rig = Rig();

      final record = await rig.install(gmx(), approve: false);

      expect(record, isNull);
      expect(rig.files.files, isEmpty);
      expect(rig.store.records, isEmpty);
    });
  });

  group('the repository is not trusted', () {
    test('an archive with a different id is refused', () async {
      final rig = Rig();

      await expectLater(
        rig.install(gmx(id: 'com.evil.other')),
        installFails('does not match'),
      );
      expect(rig.files.files, isEmpty);
      expect(rig.prompts, isEmpty);
    });

    test('an archive with a different version is refused', () async {
      final rig = Rig();

      await expectLater(
        rig.install(gmx(version: '9.9.9')),
        installFails('Archive version 9.9.9'),
      );
      expect(rig.files.files, isEmpty);
    });

    test('a corrupt archive is refused and nothing is written', () async {
      final rig = Rig();

      await expectLater(
        rig.install(Uint8List.fromList(List.filled(50, 1))),
        installFails('Not a valid extension'),
      );
      expect(rig.files.files, isEmpty);
      expect(rig.store.records, isEmpty);
    });

    test('a hash mismatch fails in the downloader', () async {
      final rig = Rig();
      final good = gmx();
      rig.served = gmx(version: '1.0.1'); // different bytes than the entry

      await expectLater(
        rig.manager.install(entryFor(good), repoA, confirm: (_) async => true),
        throwsA(isA<ArchiveDownloadException>()),
      );
      expect(rig.files.files, isEmpty);
    });
  });

  group('apiVersion', () {
    test('an entry that is too new makes no request', () async {
      final rig = Rig(supportedApi: 1);

      await expectLater(
        rig.install(gmx(apiVersion: 2), api: 2),
        installFails('Update the app'),
      );
      expect(rig.requests, 0);
    });

    test(
      'an archive that is too new is refused even if the entry lies',
      () async {
        final rig = Rig(supportedApi: 1);

        await expectLater(
          rig.install(gmx(apiVersion: 2), api: 1),
          installFails('Update the app'),
        );
        expect(rig.files.files, isEmpty);
      },
    );

    test('the supported version itself is accepted', () async {
      final rig = Rig(supportedApi: 2);

      expect(await rig.install(gmx(apiVersion: 2), api: 2), isNotNull);
    });
  });

  group('failure cleanup', () {
    test('a failed save removes the new file', () async {
      final rig = Rig();
      rig.store.failOnSave = StateError('db down');

      await expectLater(rig.install(gmx()), throwsStateError);

      expect(rig.files.files, isEmpty);
    });

    test('a failed update save puts the old archive back', () async {
      final rig = Rig();
      final v1 = gmx();
      await rig.install(v1);
      rig.store.failOnSave = StateError('db down');

      await expectLater(
        rig.install(gmx(version: '1.1.0'), version: '1.1.0'),
        throwsStateError,
      );

      expect(await rig.files.read('com.example.music'), v1);
      expect((await rig.store.all()).single.version, '1.0.0');
    });
  });

  group('updates', () {
    test('a downgrade is refused', () async {
      final rig = Rig();
      await rig.install(gmx(version: '2.0.0'), version: '2.0.0');

      await expectLater(
        rig.install(gmx(version: '1.0.0')),
        installFails('not newer'),
      );
    });

    test('the same version is refused', () async {
      final rig = Rig();
      await rig.install(gmx());

      await expectLater(rig.install(gmx()), installFails('not newer'));
    });

    test('a newer version with the same permissions is silent', () async {
      final rig = Rig();
      await rig.install(gmx(permissions: net));
      rig.prompts.clear();

      final record = await rig.install(
        gmx(version: '1.1.0', permissions: net),
        version: '1.1.0',
      );

      expect(rig.prompts, isEmpty);
      expect(record!.version, '1.1.0');
    });

    test('an update keeps enabled and the original install time', () async {
      final rig = Rig();
      await rig.install(gmx());
      await rig.store.save(
        (await rig.store.all()).single.copyWith(enabled: true),
      );
      rig.now = DateTime.utc(2026, 1, 1);

      final record = await rig.install(gmx(version: '1.1.0'), version: '1.1.0');

      expect(record!.enabled, isTrue);
      expect(record.installedAt, DateTime.utc(2025, 1, 1));
    });

    test('added storage asks again', () async {
      final rig = Rig();
      await rig.install(gmx());
      rig.prompts.clear();

      await rig.install(
        gmx(version: '1.1.0', permissions: {'storage': true}),
        version: '1.1.0',
      );

      expect(rig.prompts.single.permissionsGrew, isTrue);
      expect(rig.prompts.single.isUpdate, isTrue);
    });

    test('a new network domain asks again', () async {
      final rig = Rig();
      await rig.install(gmx(permissions: net));
      rig.prompts.clear();

      await rig.install(
        gmx(
          version: '1.1.0',
          permissions: {
            'network': {
              'domains': ['api.example.com', 'evil.example.net'],
            },
          },
        ),
        version: '1.1.0',
      );

      expect(rig.prompts.single.permissionsGrew, isTrue);
    });

    test('removing permissions does not ask', () async {
      final rig = Rig();
      await rig.install(gmx(permissions: {'storage': true, ...net}));
      rig.prompts.clear();

      await rig.install(gmx(version: '1.1.0'), version: '1.1.0');

      expect(rig.prompts, isEmpty);
    });

    test('declining an update keeps the old version', () async {
      final rig = Rig();
      final v1 = gmx();
      await rig.install(v1);

      final record = await rig.install(
        gmx(version: '1.1.0', permissions: {'storage': true}),
        version: '1.1.0',
        approve: false,
      );

      expect(record, isNull);
      expect(await rig.files.read('com.example.music'), v1);
      expect((await rig.store.all()).single.version, '1.0.0');
    });

    test('a different repository asks again', () async {
      final rig = Rig();
      await rig.install(gmx());
      rig.prompts.clear();

      await rig.install(
        gmx(version: '1.1.0'),
        version: '1.1.0',
        repo: repoB,
      );

      expect(rig.prompts.single.sourceChanged, isTrue);
      expect((await rig.store.all()).single.repositoryUrl, repoB);
    });

    test(
      'an unreadable previous archive counts as grown permissions',
      () async {
        final rig = Rig();
        await rig.install(gmx());
        await rig.files.write(
          'com.example.music',
          Uint8List.fromList([1, 2, 3]),
        );
        rig.prompts.clear();

        await rig.install(gmx(version: '1.1.0'), version: '1.1.0');

        expect(rig.prompts.single.permissionsGrew, isTrue);
      },
    );
  });
}
