import 'package:extension_capabilities/extension_capabilities.dart';
import 'package:extension_host/extension_host.dart';
import 'package:flutter_test/flutter_test.dart';
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

  Future<ExtensionHost> start(
    String script, {
    Map<String, Object?> permissions = const {},
  }) async {
    final host = await ExtensionHost.start(
      buildArchive(script, permissions: permissions),
      storageFor: (_) => _MemoryStorage(),
      logSink: (_, _, _) {},
      httpClient: MockClient(
        (_) async => throw StateError('no network in tests'),
      ),
      timeout: const Duration(seconds: 5),
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
