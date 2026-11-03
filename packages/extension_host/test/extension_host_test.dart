import 'package:extension_capabilities/extension_capabilities.dart';
import 'package:extension_host/extension_host.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers.dart';

class _MemoryStorage implements ExtensionStorage {
  final data = <String, Object?>{};
  @override
  Future<Object?> get(String key) async => data[key];
  @override
  Future<void> set(String key, Object? value) async => data[key] = value;
  @override
  Future<void> remove(String key) async => data.remove(key);
  @override
  Future<List<String>> keys() async => data.keys.toList();
  @override
  Future<void> clear() async => data.clear();
}

void main() {
  final started = <ExtensionHost>[];

  late List<http.BaseRequest> requests;

  Future<ExtensionHost> start(
    String script, {
    Map<String, Object?> permissions = const {},
    http.Client? client,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    requests = [];
    final host = await ExtensionHost.start(
      buildArchive(script, permissions: permissions),
      storageFor: (_) => _MemoryStorage(),
      logSink: (_, _, _) {},
      httpClient:
          client ??
          MockClient((request) async {
            requests.add(request);
            return http.Response('{"ok":true}', 200);
          }),
      timeout: timeout,
    );
    started.add(host);
    return host;
  }

  tearDown(() {
    for (final host in started) {
      host.dispose(); // idempotent
    }
    started.clear();
  });

  group('start', () {
    test('exposes the metadata from the archive', () async {
      final host = await start('(ctx) => ({ ping: () => 1 })');

      expect(host.metadata.id, 'com.example.test');
      expect(host.isDisposed, isFalse);
    });

    test('fails when the script is not a valid extension', () async {
      await expectLater(start('42'), throwsStateError);
    });

    test('fails when the script throws while loading', () async {
      await expectLater(
        start('(ctx) => { throw new Error("bad"); }'),
        throwsStateError,
      );
    });
  });

  group('invoke', () {
    test('returns the value of a sync method', () async {
      final host = await start('(ctx) => ({ ping: () => "pong" })');

      expect(await host.invoke('ping'), 'pong');
    });

    test('awaits an async method', () async {
      final host = await start(
        '(ctx) => ({ add: async (a, b) => { await 0; return a + b; } })',
      );

      expect(await host.invoke('add', [1, 2]), 3);
    });

    test('a missing method is an error', () async {
      final host = await start('(ctx) => ({ ping: () => 1 })');

      await expectLater(host.invoke('nope'), throwsStateError);
    });

    test('an error thrown by the extension surfaces its message', () async {
      final host = await start(
        '(ctx) => ({ bad: () => { throw new Error("upstream down"); } })',
      );

      await expectLater(
        host.invoke('bad'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('upstream down'),
          ),
        ),
      );
    });

    test('the host keeps working after a method fails', () async {
      final host = await start('''
        (ctx) => ({
          bad: () => { throw new Error("x"); },
          good: () => "ok",
        })
      ''');

      await expectLater(host.invoke('bad'), throwsStateError);
      expect(await host.invoke('good'), 'ok');
    });
  });

  group('permissions', () {
    test('only log is granted by default', () async {
      final host = await start(
        '(ctx) => ({ keys: () => Object.keys(ctx).sort() })',
      );

      expect(await host.invoke('keys'), ['log']);
    });

    test('storage is granted when declared', () async {
      final host = await start(
        '(ctx) => ({ keys: () => Object.keys(ctx).sort() })',
        permissions: {'storage': true},
      );

      expect(await host.invoke('keys'), ['log', 'storage']);
    });

    test('http appears when network domains are declared', () async {
      final host = await start(
        '(ctx) => ({ keys: () => Object.keys(ctx).sort() })',
        permissions: {
          'network': {
            'domains': ['api.example.com'],
          },
        },
      );

      expect(await host.invoke('keys'), ['http', 'log']);
    });

    test('log can be turned off', () async {
      final host = await start(
        '(ctx) => ({ keys: () => Object.keys(ctx).sort() })',
        permissions: {'log': false},
      );

      expect(await host.invoke('keys'), isEmpty);
    });

    test('storage works when granted', () async {
      final host = await start(
        '''
        (ctx) => ({
          run: async () => {
            await ctx.storage.set('k', 1);
            return ctx.storage.get('k');
          },
        })
      ''',
        permissions: {'storage': true},
      );

      expect(await host.invoke('run'), 1);
    });

    test('an ungranted capability is undefined, not just refused', () async {
      final host = await start('(ctx) => ({ t: () => typeof ctx.storage })');

      expect(await host.invoke('t'), 'undefined');
    });

    test('sendMessage is not reachable', () async {
      final host = await start('(ctx) => ({ t: () => typeof sendMessage })');

      expect(await host.invoke('t'), 'undefined');
    });
  });

  group('network', () {
    const fetchScript = '''
      (ctx) => ({
        get: async (url) => {
          try { return await ctx.http.fetch(url); }
          catch (e) { return { error: e.message }; }
        },
      })
    ''';

    final perms = {
      'network': {
        'domains': ['api.example.com'],
      },
    };

    test('a declared domain can be fetched', () async {
      final host = await start(fetchScript, permissions: perms);

      final result =
          await host.invoke('get', ['https://api.example.com/x']) as Map;

      expect(result['status'], 200);
      expect(result['body'], '{"ok":true}');
      expect(requests, hasLength(1));
    });

    test('an undeclared domain is refused and makes no request', () async {
      final host = await start(fetchScript, permissions: perms);

      final result = await host.invoke('get', ['https://evil.com/']) as Map;

      expect(result['error'], contains('Domain not allowed'));
      expect(requests, isEmpty);
    });

    test('a wildcard declaration allows subdomains only', () async {
      final host = await start(
        fetchScript,
        permissions: {
          'network': {
            'domains': ['*.example.com'],
          },
        },
      );

      final ok = await host.invoke('get', ['https://cdn.example.com/']) as Map;
      final bare = await host.invoke('get', ['https://example.com/']) as Map;

      expect(ok['status'], 200);
      expect(bare['error'], contains('Domain not allowed'));
    });

    test('http (not https) is refused', () async {
      final host = await start(fetchScript, permissions: perms);

      final result =
          await host.invoke('get', ['http://api.example.com/']) as Map;

      expect(result['error'], contains('Only https'));
      expect(requests, isEmpty);
    });

    test('without a network permission, ctx.http does not exist', () async {
      final host = await start('(ctx) => ({ t: () => typeof ctx.http })');

      expect(await host.invoke('t'), 'undefined');
    });

    test('a slow request fails in JS before the bridge times out', () async {
      final host = await start(
        fetchScript,
        permissions: perms,
        timeout: const Duration(milliseconds: 900),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(seconds: 3));
          return http.Response('late', 200);
        }),
      );

      // Network timeout is 2/3 of 900ms = 600ms, so JS gets an error and the
      // bridge (900ms) stays alive.
      final result =
          await host.invoke('get', ['https://api.example.com/']) as Map;

      expect(result['error'], isNotNull);
      expect(host.isDisposed, isFalse);
    });
  });

  group('dispose', () {
    test('marks the host as disposed', () async {
      final host = await start('(ctx) => ({ ping: () => 1 })');

      host.dispose();

      expect(host.isDisposed, isTrue);
    });

    test('is idempotent', () async {
      final host = await start('(ctx) => ({ ping: () => 1 })');

      host.dispose();

      expect(host.dispose, returnsNormally);
    });

    test('invoke throws StateError afterwards', () async {
      final host = await start('(ctx) => ({ ping: () => 1 })');

      host.dispose();

      expect(() => host.invoke('ping'), throwsStateError);
    });
  });
}
