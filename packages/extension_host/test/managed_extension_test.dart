import 'dart:async';

import 'package:extension_host/extension_host.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers.dart';

const _script = '''
  (ctx) => {
    let n = 0;
    return {
      count: () => ++n,
      hang: () => new Promise(() => {}),
      browse: async () => ({ header: { title: 'home' } }),
    };
  }
''';

void main() {
  final created = <ManagedExtension>[];

  ManagedExtension create({
    String script = _script,
    Duration timeout = const Duration(seconds: 5),
  }) {
    final m = ManagedExtension(
      buildArchive(script),
      storageFor: (_) => throw StateError('storage not granted'),
      logSink: (_, _, _) {},
      httpClient: MockClient((_) async => http.Response('', 200)),
      timeout: timeout,
    );
    created.add(m);
    return m;
  }

  tearDown(() {
    for (final m in created) {
      m.close();
    }
    created.clear();
  });

  test('does not start until the first call', () {
    final m = create();

    expect(m.starts, 0);
  });

  test('starts on the first call and reuses the runtime', () async {
    final m = create();

    expect(await m.invoke('count'), 1);
    expect(await m.invoke('count'), 2);
    expect(m.starts, 1);
  });

  test('exposes the metadata without starting', () {
    expect(create().metadata.id, 'com.example.test');
  });

  test('concurrent first calls share one start', () async {
    final m = create();

    final results = await Future.wait([m.invoke('count'), m.invoke('count')]);

    expect(m.starts, 1);
    expect(results, unorderedEquals([1, 2]));
  });

  test('typed methods work', () async {
    final m = create();

    expect((await m.browse()).header!.title, 'home');
  });

  group('restart', () {
    test('after a timeout the next call gets a fresh runtime', () async {
      final m = create(timeout: const Duration(milliseconds: 300));
      expect(await m.invoke('count'), 1);
      expect(await m.invoke('count'), 2);

      await expectLater(m.invoke('hang'), throwsA(isA<TimeoutException>()));

      expect(await m.invoke('count'), 1); // JS memory was reset
      expect(m.starts, 2);
    });

    test('the call that timed out is not retried', () async {
      final m = create(timeout: const Duration(milliseconds: 300));

      await expectLater(m.invoke('hang'), throwsA(isA<TimeoutException>()));

      expect(m.starts, 1);
    });

    test('keeps restarting after repeated timeouts', () async {
      final m = create(timeout: const Duration(milliseconds: 200));

      for (var i = 0; i < 3; i++) {
        await expectLater(m.invoke('hang'), throwsA(isA<TimeoutException>()));
      }

      expect(await m.invoke('count'), 1);
      expect(m.starts, 4);
    });

    test('an extension error does not restart the runtime', () async {
      final m = create(
        script:
            '(ctx) => ({ bad: () => { throw new Error("x"); }, ok: () => 1 })',
      );

      await expectLater(m.invoke('bad'), throwsStateError);
      await m.invoke('ok');

      expect(m.starts, 1);
    });
  });

  group('start failures', () {
    test(
      'a script that fails to load throws and is retried next call',
      () async {
        final m = create(script: '42');

        await expectLater(m.invoke('x'), throwsStateError);
        await expectLater(m.invoke('x'), throwsStateError);

        expect(m.starts, 0);
      },
    );
  });

  group('close', () {
    test('later calls throw StateError', () async {
      final m = create();
      await m.invoke('count');

      m.close();

      expect(m.isClosed, isTrue);
      await expectLater(m.invoke('count'), throwsStateError);
    });

    test('is idempotent', () {
      final m = create();

      m.close();

      expect(m.close, returnsNormally);
    });

    test('closing before the first call prevents a start', () async {
      final m = create();

      m.close();

      await expectLater(m.browse(), throwsStateError);
      expect(m.starts, 0);
    });
  });
}
