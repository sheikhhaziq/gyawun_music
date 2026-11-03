import 'dart:convert';

import 'package:extension_capabilities/extension_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

http.StreamedResponse _reply(
  String body, {
  int status = 200,
  Map<String, String> headers = const {},
}) => http.StreamedResponse(
  Stream.value(utf8.encode(body)),
  status,
  headers: headers,
);

void main() {
  late JsBridge js;
  late _MemoryStorage store;
  late List<(LogLevel, String)> logs;
  late List<http.BaseRequest> requests;

  /// Wires the full stack and loads [source] as the extension.
  void start(
    String source,
    http.StreamedResponse Function(http.BaseRequest) responder, {
    int maxResponseBytes = 1000,
  }) {
    store = _MemoryStorage();
    logs = [];
    requests = [];

    final router = CapabilityRouter([
      StorageCapability(store),
      LoggingCapability(
        extensionId: 'test.ext',
        sink: (_, level, message) => logs.add((level, message)),
      ),
      NetworkCapability(
        policy: DomainPolicy(['api.example.com']),
        client: MockClient.streaming((request, _) async {
          requests.add(request);
          return responder(request);
        }),
        maxResponseBytes: maxResponseBytes,
      ),
    ]);

    js = JsBridge(runtime: createRuntime(), onAction: router.handle);
    js.load(buildExtensionScript(source, granted: {'storage', 'log', 'http'}));
  }

  Future<Object?> invoke(String method, [List<Object?> args = const []]) =>
      js.call('__extensionCall', arguments: [method, ...args]);

  tearDown(() => js.dispose());

  /// An extension whose `run` returns the fetch result, or the error message.
  const fetcher = '''
    (ctx) => ({
      run: async (url) => {
        try { return await ctx.http.fetch(url); }
        catch (e) { return { error: e.message }; }
      },
    })
  ''';

  group('http.fetch', () {
    test('returns status, headers and body to JS', () async {
      start(
        fetcher,
        (_) => _reply('hello', status: 201, headers: {'x-a': 'b'}),
      );

      final result = await invoke('run', ['https://api.example.com/x']) as Map;

      expect(result['status'], 201);
      expect(result['body'], 'hello');
      expect((result['headers'] as Map)['x-a'], 'b');
    });

    test('sends method, headers and body from JS', () async {
      start('''
        (ctx) => ({
          run: () => ctx.http.fetch('https://api.example.com/items', {
            method: 'POST',
            headers: { 'X-Token': 'abc' },
            body: '{"a":1}',
          }),
        })
      ''', (_) => _reply('ok'));

      await invoke('run');

      final request = requests.single as http.Request;
      expect(request.method, 'POST');
      expect(request.headers['x-token'], 'abc');
      expect(request.body, '{"a":1}');
    });

    test('a 404 reaches JS as a normal result', () async {
      start(fetcher, (_) => _reply('nope', status: 404));

      final result = await invoke('run', ['https://api.example.com/']) as Map;

      expect(result['status'], 404);
    });
  });

  group('policy end to end', () {
    test('a forbidden domain is an error in JS and makes no request', () async {
      start(fetcher, (_) => _reply('should not happen'));

      final result = await invoke('run', ['https://evil.com/']) as Map;

      expect(result['error'], contains('Domain not allowed'));
      expect(requests, isEmpty);
    });

    test('http is refused', () async {
      start(fetcher, (_) => _reply(''));

      final result = await invoke('run', ['http://api.example.com/']) as Map;

      expect(result['error'], contains('Only https'));
      expect(requests, isEmpty);
    });

    test('a redirect to a forbidden host is blocked', () async {
      start(
        fetcher,
        (_) =>
            _reply('', status: 302, headers: {'location': 'https://evil.com/'}),
      );

      final result = await invoke('run', ['https://api.example.com/']) as Map;

      expect(result['error'], contains('Domain not allowed'));
      expect(requests, hasLength(1));
    });

    test('an oversized response fails inside JS', () async {
      start(fetcher, (_) => _reply('a' * 101), maxResponseBytes: 100);

      final result = await invoke('run', ['https://api.example.com/']) as Map;

      expect(result['error'], contains('exceeds'));
    });
  });

  group('realistic extension', () {
    test('fetches, parses, stores and logs', () async {
      start('''
        (ctx) => ({
          browse: async () => {
            ctx.log.info('browse started');
            const res = await ctx.http.fetch('https://api.example.com/browse');
            const data = JSON.parse(res.body);
            await ctx.storage.set('last', data);
            ctx.log.info('stored', data.items.length, 'items');
            return { sections: [{ title: 'Trending', items: data.items }] };
          },
        })
      ''', (_) => _reply('{"items":["a","b"]}'));

      final result = await invoke('browse');

      expect(result, {
        'sections': [
          {
            'title': 'Trending',
            'items': ['a', 'b'],
          },
        ],
      });
      expect(store.data['last'], {
        'items': ['a', 'b'],
      });
      expect(logs.map((l) => l.$2), ['browse started', 'stored 2 items']);
    });

    test(
      'a network failure can be caught and logged by the extension',
      () async {
        start('''
        (ctx) => ({
          browse: async () => {
            try {
              await ctx.http.fetch('https://evil.com/');
              return 'unexpected';
            } catch (e) {
              ctx.log.error('fetch failed:', e.message);
              await ctx.storage.keys(); // lets the log flush
              return 'recovered';
            }
          },
        })
      ''', (_) => _reply(''));

        expect(await invoke('browse'), 'recovered');
        expect(logs.single.$1, LogLevel.error);
        expect(logs.single.$2, contains('Domain not allowed'));
      },
    );
  });
}
