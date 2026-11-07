import 'package:extension_capabilities/extension_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:js_bridge/js_bridge.dart';

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
  final created = <JsBridge>[];
  late JsBridge js;
  late _MemoryStorage store;
  late List<(LogLevel, String)> logs;

  JsBridge newBridge(CapabilityRouter router) {
    js = JsBridge(runtime: createRuntime(), onAction: router.handle);
    created.add(js);
    return js;
  }

  /// Builds a bridge whose router grants only [granted], then loads [source].
  void start(String source, {Set<String> granted = const {'storage', 'log'}}) {
    store = _MemoryStorage();
    logs = [];
    final router = CapabilityRouter([
      if (granted.contains('storage')) StorageCapability(store),
      if (granted.contains('log'))
        LoggingCapability(
          extensionId: 'test.ext',
          sink: (_, level, message) => logs.add((level, message)),
        ),
    ]);
    newBridge(router).load(buildExtensionScript(source, granted: granted));
  }

  Future<Object?> invoke(String method, [List<Object?> args = const []]) =>
      js.call('__extensionCall', arguments: [method, ...args]);

  tearDown(() {
    for (final bridge in created) {
      bridge.dispose(); // idempotent
    }
    created.clear();
  });

  group('loading', () {
    test('accepts a function returning methods', () async {
      start('(ctx) => ({ ping: () => "pong" })');

      expect(await invoke('ping'), 'pong');
    });

    test('accepts an esbuild-style bundle', () async {
      start('''
        var ext = (() => {
          const def = { ping: () => "pong" };
          return { default: (ctx) => def };
        })();
        ext.default;
      ''');

      expect(await invoke('ping'), 'pong');
    });

    test('rejects source that is not a function', () {
      expect(() => start('42'), throwsStateError);
    });

    test('rejects a function that does not return an object', () {
      expect(() => start('(ctx) => 5'), throwsStateError);
      expect(() => start('(ctx) => null'), throwsStateError);
    });

    test('rejects a member that is not a function', () {
      expect(() => start('(ctx) => ({ a: 1 })'), throwsStateError);
    });

    test('rejects a syntax error', () {
      expect(() => start('(ctx) => ({'), throwsStateError);
    });

    test('rejects a factory that throws', () {
      expect(
        () => start('(ctx) => { throw new Error("bad"); }'),
        throwsStateError,
      );
    });

    test('treats the source as data, not as wrapper code', () async {
      start('''
        (ctx) => ({ s: () => "}); throw new Error('escaped'); (function(){" })
      ''');

      expect(await invoke('s'), "}); throw new Error('escaped'); (function(){");
    });
  });

  group('methods', () {
    test('passes arguments and awaits async methods', () async {
      start('(ctx) => ({ add: async (a, b) => { await 0; return a + b; } })');

      expect(await invoke('add', [1, 2]), 3);
    });

    test('a missing method is an error', () async {
      start('(ctx) => ({ ping: () => 1 })');

      await expectLater(
        invoke('nope'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('does not implement: nope'),
          ),
        ),
      );
    });

    test('an error thrown by a method surfaces its message', () async {
      start('(ctx) => ({ bad: () => { throw new Error("upstream down"); } })');

      await expectLater(
        invoke('bad'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('upstream down'),
          ),
        ),
      );
    });

    test('the entry point cannot be replaced by the extension', () async {
      start('''
        (ctx) => ({
          a: () => "a",
          tamper: () => {
            try { globalThis.__extensionCall = () => "hacked"; } catch (_) {}
            return "done";
          },
        })
      ''');

      await invoke('tamper');

      expect(await invoke('a'), 'a');
    });
    test('__extensionMethods lists what the extension returned', () async {
      start('(ctx) => ({ a: () => 1, b: async () => 2 })');

      final names = await js.call('__extensionMethods') as List;

      expect(names, unorderedEquals(['a', 'b']));
    });

    test('__extensionMethods cannot be replaced', () async {
      start('''
        (ctx) => ({
          t: () => {
            try { globalThis.__extensionMethods = () => ['x']; } catch (_) {}
            return 'done';
          },
        })
      ''');

      await invoke('t');

      expect(await js.call('__extensionMethods'), ['t']);
    });
  });

  group('sandbox', () {
    test('sendMessage is not reachable by the extension', () async {
      start('(ctx) => ({ t: () => typeof sendMessage })');

      expect(await invoke('t'), 'undefined');
    });

    test('the context is frozen', () async {
      start('''
        (ctx) => ({
          t: () => {
            try { ctx.storage = null; } catch (_) {}
            return typeof ctx.storage;
          },
        })
      ''');

      expect(await invoke('t'), 'object');
    });

    test('capability objects are frozen', () async {
      start('''
        (ctx) => ({
          t: () => {
            try { ctx.storage.get = null; } catch (_) {}
            return typeof ctx.storage.get;
          },
        })
      ''');

      expect(await invoke('t'), 'function');
    });

    test('only granted capabilities exist on the context', () async {
      start(
        '(ctx) => ({ t: () => Object.keys(ctx).sort() })',
        granted: {'storage'},
      );

      expect(await invoke('t'), ['storage']);
    });

    test('an ungranted capability is undefined', () async {
      start(
        '(ctx) => ({ t: () => typeof ctx.http })',
        granted: {'storage', 'log'},
      );

      expect(await invoke('t'), 'undefined');
    });

    test('granting everything exposes storage, log and http', () async {
      start(
        '(ctx) => ({ t: () => Object.keys(ctx).sort() })',
        granted: {'storage', 'log', 'http'},
      );

      expect(await invoke('t'), ['http', 'log', 'storage']);
    });
  });

  group('storage', () {
    test('set then get round-trips through Dart', () async {
      start('''
        (ctx) => ({
          run: async () => {
            await ctx.storage.set('k', { a: [1, 2] });
            return ctx.storage.get('k');
          },
        })
      ''');

      expect(await invoke('run'), {
        'a': [1, 2],
      });
      expect(store.data['k'], {
        'a': [1, 2],
      });
    });

    test('get of a missing key is null', () async {
      start('(ctx) => ({ run: () => ctx.storage.get("nope") })');

      expect(await invoke('run'), isNull);
    });

    test('keys, remove and clear work', () async {
      start('''
        (ctx) => ({
          run: async () => {
            await ctx.storage.set('a', 1);
            await ctx.storage.set('b', 2);
            const before = (await ctx.storage.keys()).sort();
            await ctx.storage.remove('a');
            const afterRemove = await ctx.storage.keys();
            await ctx.storage.clear();
            const afterClear = await ctx.storage.keys();
            return { before, afterRemove, afterClear };
          },
        })
      ''');

      expect(await invoke('run'), {
        'before': ['a', 'b'],
        'afterRemove': ['b'],
        'afterClear': [],
      });
    });

    test('a host validation error becomes a JS error', () async {
      start('''
        (ctx) => ({
          run: async () => {
            try { await ctx.storage.get(''); return 'no error'; }
            catch (e) { return e.message; }
          },
        })
      ''');

      expect(await invoke('run'), contains('Key must be'));
    });
  });

  group('log', () {
    test('sends each level to the sink', () async {
      start('''
        (ctx) => ({
          run: async () => {
            ctx.log.debug('d'); ctx.log.info('i');
            ctx.log.warn('w'); ctx.log.error('e');
            await ctx.storage.keys(); // lets the log messages flush
          },
        })
      ''');

      await invoke('run');

      expect(logs.map((l) => l.$1), orderedEquals(LogLevel.values));
    });

    test('joins parts and formats objects', () async {
      start('''
        (ctx) => ({
          run: async () => {
            ctx.log.info('user', { id: 7 }, 3);
            await ctx.storage.keys();
          },
        })
      ''');

      await invoke('run');

      expect(logs.single.$2, 'user {"id":7} 3');
    });

    test('a failing sink does not break the extension', () async {
      final router = CapabilityRouter([
        StorageCapability(_MemoryStorage()),
        LoggingCapability(
          extensionId: 'test.ext',
          sink: (_, _, _) => throw StateError('disk full'),
        ),
      ]);
      newBridge(router).load(
        buildExtensionScript(
          '''
        (ctx) => ({
          run: async () => {
            ctx.log.info('x');
            await ctx.storage.keys();
            return 'still running';
          },
        })
      ''',
          granted: {'storage', 'log'},
        ),
      );

      expect(await invoke('run'), 'still running');
    });
  });

  group('grants vs the router', () {
    test('the router still refuses what it was not given', () async {
      // The script exposes storage, but the router has no storage capability.
      // The router is the real boundary.
      newBridge(CapabilityRouter(const [])).load(
        buildExtensionScript(
          '''
        (ctx) => ({
          run: async () => {
            try { await ctx.storage.keys(); return 'no error'; }
            catch (e) { return e.message; }
          },
        })
      ''',
          granted: {'storage'},
        ),
      );

      expect(await invoke('run'), contains('Capability not granted: storage'));
    });

    test('http.fetch without a network capability fails clearly', () async {
      newBridge(CapabilityRouter(const [])).load(
        buildExtensionScript(
          '''
        (ctx) => ({
          run: async () => {
            try { await ctx.http.fetch('https://api.example.com/'); return 'no error'; }
            catch (e) { return e.message; }
          },
        })
      ''',
          granted: {'http'},
        ),
      );

      expect(await invoke('run'), contains('Capability not granted: network'));
    });
  });
}
