import 'package:extension_api/extension_api.dart';
import 'package:extension_host/extension_host.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers.dart';

void main() {
  final started = <ExtensionHost>[];

  Future<ExtensionHost> start(String script, {bool withBrowse = true}) async {
    final host = await ExtensionHost.start(
      buildArchive(script, withBrowse: withBrowse),
      storageFor: (_) => throw StateError('storage not granted'),
      logSink: (_, _, _) {},
      httpClient: MockClient((_) async => http.Response('', 200)),
      timeout: const Duration(seconds: 5),
    );
    started.add(host);
    return host;
  }

  tearDown(() {
    for (final h in started) {
      h.dispose();
    }
    started.clear();
  });

  Endpoint<R> endpoint<R>() => Endpoint.parse<R>('e', 'e');

  group('browse only', () {
    test('an extension with only browse starts and works', () async {
      final host = await start(
        '(ctx) => ({ browse: async () => ({ header: { title: "H" } }) })',
        withBrowse: false,
      );

      expect(host.methods, {'browse'});
      expect((await host.browse()).header!.title, 'H');
    });

    test(
      'an empty result is valid: no sections, chips or continuation',
      () async {
        final host = await start(
          '(ctx) => ({ browse: async () => ({}) })',
          withBrowse: false,
        );

        final r = await host.browse();

        expect(r.sections, isEmpty);
        expect(r.chips, isEmpty);
        expect(r.continuation, isNull);
      },
    );

    test('a section with no trailing action is valid', () async {
      final host = await start('''
        (ctx) => ({
          browse: async () => ({
            sections: [{ title: 'S', items: [{ kind: 'song', title: 'T' }] }],
          }),
        })
      ''', withBrowse: false);

      expect((await host.browse()).sections.single.action, isNull);
    });
  });

  group('start checks', () {
    test(
      'fails when browse is provided but there is no browse method',
      () async {
        await expectLater(
          start('(ctx) => ({ ping: () => 1 })', withBrowse: false),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('no browse method'),
            ),
          ),
        );
      },
    );

    test('exposes the method names', () async {
      final host = await start('(ctx) => ({ items: async () => ({}) })');

      expect(host.methods, {'browse', 'items'});
    });

    test('the method set is unmodifiable', () async {
      final host = await start('(ctx) => ({})');

      expect(() => host.methods.add('x'), throwsUnsupportedError);
    });
  });

  group('optional methods', () {
    test(
      'items without an implementation is a descriptive StateError',
      () async {
        final host = await start('(ctx) => ({})');

        await expectLater(
          host.items(endpoint<ItemsResult>()),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              allOf(contains('com.example.test'), contains('"items"')),
            ),
          ),
        );
      },
    );

    test('queue and getStream behave the same', () async {
      final host = await start('(ctx) => ({})');

      await expectLater(host.queue(endpoint<QueueResult>()), throwsStateError);
      await expectLater(
        host.getStream(endpoint<StreamResult>()),
        throwsStateError,
      );
    });

    test('a missing optional method does not dispose the host', () async {
      final host = await start('(ctx) => ({})');

      await expectLater(host.items(endpoint<ItemsResult>()), throwsStateError);

      expect(host.isDisposed, isFalse);
      expect((await host.browse()).sections, isEmpty);
    });

    test('implemented optional methods work', () async {
      final host = await start('''
        (ctx) => ({
          items: async () => ({ items: [{ kind: 'album', title: 'A' }] }),
          queue: async () => ({ items: [{ kind: 'song', title: 'S' }] }),
        })
      ''');

      expect(
        (await host.items(endpoint<ItemsResult>())).items.single.title,
        'A',
      );
      expect(
        (await host.queue(endpoint<QueueResult>())).items.single.title,
        'S',
      );
    });
  });
}
