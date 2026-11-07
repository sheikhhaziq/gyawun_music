import 'package:extension_api/extension_api.dart';
import 'package:extension_host/extension_host.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers.dart';

void main() {
  final started = <ExtensionHost>[];

  Future<ExtensionHost> start(String script) async {
    final host = await ExtensionHost.start(
      buildArchive(script),
      storageFor: (_) => throw StateError('storage not granted'),
      logSink: (_, _, _) {},
      httpClient: MockClient((_) async => http.Response('', 200)),
      timeout: const Duration(seconds: 5),
    );
    started.add(host);
    return host;
  }

  tearDown(() {
    for (final host in started) {
      host.dispose();
    }
    started.clear();
  });

  Endpoint<R> endpoint<R>(Object? data) => Endpoint.parse<R>(data, 'e');

  Matcher invalid(String text) => throwsA(
    isA<FormatException>().having((e) => e.message, 'message', contains(text)),
  );

  group('browse', () {
    test('without an endpoint calls browse with no arguments', () async {
      final host = await start('''
        (ctx) => ({
          browse: async (...args) => ({
            header: { title: 'argc ' + args.length },
          }),
        })
      ''');

      final r = await host.browse();

      expect(r.header!.title, 'argc 0');
    });

    test('passes the endpoint data back unchanged', () async {
      final host = await start('''
        (ctx) => ({
          browse: async (e) => ({ header: { title: JSON.stringify(e) } }),
        })
      ''');

      final r = await host.browse(endpoint<BrowseResult>({'page': 2}));

      expect(r.header!.title, '{"page":2}');
    });

    test('parses sections and a continuation', () async {
      final host = await start('''
        (ctx) => ({
          browse: async () => ({
            sections: [{ title: 'S', items: [{ kind: 'song', title: 'T' }] }],
            continuation: { page: 2 },
          }),
        })
      ''');

      final r = await host.browse();

      expect(r.sections.single.items.single.title, 'T');
      expect(r.continuation!.toJson(), {'page': 2});
    });

    test('invalid data names the method and the field', () async {
      final host = await start('''
        (ctx) => ({
          browse: async () => ({
            sections: [{ items: [{ kind: 'song' }] }],
          }),
        })
      ''');

      await expectLater(
        host.browse(),
        invalid('invalid data from browse: browse.sections[0].items[0].title'),
      );
    });

    test('a result that is not an object is invalid', () async {
      final host = await start('(ctx) => ({ browse: async () => "oops" })');

      await expectLater(host.browse(), invalid('invalid data from browse'));
    });

    test('a host stays usable after invalid data', () async {
      final host = await start('''
        (ctx) => ({
          browse: async (e) => e ? 5 : { header: { title: 'ok' } },
        })
      ''');

      await expectLater(
        host.browse(endpoint<BrowseResult>('bad')),
        throwsFormatException,
      );
      expect((await host.browse()).header!.title, 'ok');
    });
  });

  group('items', () {
    test('parses items and a continuation', () async {
      final host = await start('''
        (ctx) => ({
          items: async (e) => ({
            items: [{ kind: 'album', title: 'A' }],
            continuation: e,
          }),
        })
      ''');

      final r = await host.items(endpoint<ItemsResult>('tok'));

      expect(r.items.single.kind, ItemKind.album);
      expect(r.continuation!.toJson(), 'tok');
    });

    test('invalid data names the method', () async {
      final host = await start(
        '(ctx) => ({ items: async () => ({ items: [{}] }) })',
      );

      await expectLater(
        host.items(endpoint<ItemsResult>(1)),
        invalid('invalid data from items: items.items[0]'),
      );
    });
  });

  group('queue', () {
    test('parses playable items', () async {
      final host = await start('''
        (ctx) => ({
          queue: async () => ({ items: [{ kind: 'song', title: 'S' }] }),
        })
      ''');

      final r = await host.queue(endpoint<QueueResult>({'a': 'play'}));

      expect(r.items.single.title, 'S');
    });

    test('rejects an album in a queue', () async {
      final host = await start('''
        (ctx) => ({
          queue: async () => ({ items: [{ kind: 'album', title: 'A' }] }),
        })
      ''');

      await expectLater(
        host.queue(endpoint<QueueResult>(1)),
        invalid('invalid data from queue: queue.items[0].kind'),
      );
    });
  });

  group('getStream', () {
    test('parses sources and expiry', () async {
      final host = await start('''
        (ctx) => ({
          getStream: async () => ({
            sources: [{ url: 'https://cdn.example.com/a.m4a', bitrate: 128000 }],
            expiresInSeconds: 3600,
          }),
        })
      ''');

      final r = await host.getStream(endpoint<StreamResult>({'id': 1}));

      expect(r.sources.single.bitrate, 128000);
      expect(r.expiresInSeconds, 3600);
    });

    test('rejects an http stream URL', () async {
      final host = await start('''
        (ctx) => ({
          getStream: async () => ({ sources: [{ url: 'http://a.com/x' }] }),
        })
      ''');

      await expectLater(
        host.getStream(endpoint<StreamResult>(1)),
        invalid('invalid data from getStream: getStream.sources[0].url'),
      );
    });

    test('rejects a disallowed header', () async {
      final host = await start('''
        (ctx) => ({
          getStream: async () => ({
            sources: [{ url: 'https://a.com/x', headers: { cookie: 'x' } }],
          }),
        })
      ''');

      await expectLater(
        host.getStream(endpoint<StreamResult>(1)),
        invalid('not an allowed header'),
      );
    });
  });
}
