import 'package:flutter_test/flutter_test.dart';
import 'package:js_bridge/js_bridge.dart';

import 'helpers.dart';

void main() {
  final created = <JsBridge>[];
  late JsBridge js;

  JsBridge create({JsActionHandler? onAction, Duration? timeout}) {
    js = JsBridge(
      runtime: createRuntime(),
      onAction: onAction,
      timeout: timeout ?? const Duration(seconds: 5),
    );
    created.add(js);
    return js;
  }

  setUp(() => create());

  tearDown(() {
    for (final bridge in created) {
      bridge.dispose(); // idempotent
    }
    created.clear();
  });

  group('constructor', () {
    test('rejects a zero timeout', () {
      expect(
        () => JsBridge(runtime: createRuntime(), timeout: Duration.zero),
        throwsArgumentError,
      );
    });

    test('rejects a negative timeout', () {
      expect(
        () => JsBridge(
          runtime: createRuntime(),
          timeout: const Duration(seconds: -1),
        ),
        throwsArgumentError,
      );
    });

    test('starts open', () {
      expect(js.isDisposed, isFalse);
    });
  });

  group('load', () {
    test('defines globals usable by call', () async {
      js.load('function one() { return 1; }');
      expect(await js.call('one'), 1);
    });

    test('throws StateError on a syntax error', () {
      expect(() => js.load('function ('), throwsStateError);
    });

    test('throws StateError when the script throws at top level', () {
      expect(() => js.load('throw new Error("boom");'), throwsStateError);
    });
  });

  group('call', () {
    test('returns the value of a sync JS function', () async {
      js.load('function add(a, b) { return a + b; }');
      expect(await js.call('add', arguments: [1, 2]), 3);
    });

    test('awaits an async JS function', () async {
      js.load('''
        async function delayedAdd(a, b) {
          await Promise.resolve();
          return a + b;
        }
      ''');
      expect(await js.call('delayedAdd', arguments: [1, 2]), 3);
    });

    test('passes no arguments by default', () async {
      js.load('function count(...a) { return a.length; }');
      expect(await js.call('count'), 0);
    });

    test('maps undefined to null', () async {
      js.load('function nothing() {}');
      expect(await js.call('nothing'), isNull);
    });

    test('round-trips nested JSON values', () async {
      js.load('function echo(v) { return v; }');
      final value = {
        'string': 'hello',
        'int': 42,
        'double': 1.5,
        'bool': true,
        'nil': null,
        'list': [
          1,
          'two',
          {'three': 3},
        ],
        'nested': {
          'a': {'b': []},
        },
      };
      expect(await js.call('echo', arguments: [value]), value);
    });

    test('passes several arguments in order', () async {
      js.load('function join(a, b, c) { return [a, b, c].join("-"); }');
      expect(await js.call('join', arguments: ['x', 'y', 'z']), 'x-y-z');
    });

    test('treats quotes and script-like text as data', () async {
      js.load('function echo(v) { return v; }');
      const nasty =
          '"); throw new Error("injected"); (\'\\ \n \u2028 </script>';
      expect(await js.call('echo', arguments: [nasty]), nasty);
    });

    test('preserves unicode and emoji', () async {
      js.load('function echo(v) { return v; }');
      const text = 'héllo 世界 🎵';
      expect(await js.call('echo', arguments: [text]), text);
    });

    test(
      'throws StateError with the message when the function is missing',
      () async {
        await expectLater(
          js.call('doesNotExist'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Function not found: doesNotExist'),
            ),
          ),
        );
      },
    );

    test('throws StateError when the global is not a function', () async {
      js.load('var notFn = 5;');
      await expectLater(js.call('notFn'), throwsStateError);
    });

    test('surfaces a sync JS error message', () async {
      js.load('function boom() { throw new Error("kaboom"); }');
      await expectLater(
        js.call('boom'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('kaboom'),
          ),
        ),
      );
    });

    test('surfaces a rejected promise message', () async {
      js.load('''
        async function reject() { throw new Error("rejected"); }
      ''');
      await expectLater(
        js.call('reject'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('rejected'),
          ),
        ),
      );
    });

    test('surfaces a non-Error throw', () async {
      js.load('function throwString() { throw "plain string"; }');
      await expectLater(
        js.call('throwString'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('plain string'),
          ),
        ),
      );
    });

    test('includes the JS stack in the error', () async {
      js.load('function boom() { throw new Error("kaboom"); }');
      await expectLater(
        js.call('boom'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('boom'),
          ),
        ),
      );
    });

    test('a failed call does not break later calls', () async {
      js.load('''
        function boom() { throw new Error("x"); }
        function ok() { return 'fine'; }
      ''');
      await expectLater(js.call('boom'), throwsStateError);
      expect(await js.call('ok'), 'fine');
    });

    test('throws ArgumentError for a blank name', () {
      expect(() => js.call(''), throwsArgumentError);
      expect(() => js.call('   '), throwsArgumentError);
    });

    test('runs calls one at a time, in order', () async {
      js.load('''
        const log = [];
        async function a() {
          log.push('a1');
          await Promise.resolve();
          log.push('a2');
        }
        async function b() {
          log.push('b1');
          await Promise.resolve();
          log.push('b2');
        }
        function getLog() { return log; }
      ''');

      await Future.wait([js.call('a'), js.call('b')]);

      expect(await js.call('getLog'), ['a1', 'a2', 'b1', 'b2']);
    });
  });
}
