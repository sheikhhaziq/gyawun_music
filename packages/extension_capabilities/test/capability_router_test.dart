import 'dart:async';

import 'package:extension_capabilities/extension_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';

/// A test double that records calls and returns a canned result.
class FakeCapability implements Capability {
  FakeCapability(this.name, {this.result});

  @override
  final String name;
  final Object? result;

  String? lastMethod;
  Map<String, dynamic>? lastArgs;

  @override
  FutureOr<Object?> handle(String method, Map<String, dynamic> args) {
    lastMethod = method;
    lastArgs = args;
    return result;
  }
}

class _SlowCapability implements Capability {
  @override
  String get name => 'slow';

  @override
  Future<Object?> handle(String method, Map<String, dynamic> args) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return 'done';
  }
}

class _ThrowingCapability implements Capability {
  @override
  String get name => 'bad';

  @override
  Object? handle(String method, Map<String, dynamic> args) =>
      throw StateError('capability failed');
}

void main() {
  group('handle', () {
    test('routes to the capability with the matching name', () async {
      final storage = FakeCapability('storage', result: 'from storage');
      final logging = FakeCapability('logging', result: 'from logging');
      final router = CapabilityRouter([storage, logging]);

      final result = await router.handle({
        'cap': 'logging',
        'method': 'write',
        'args': {'message': 'hi'},
      });

      expect(result, 'from logging');
      expect(logging.lastMethod, 'write');
      expect(logging.lastArgs, {'message': 'hi'});
      expect(storage.lastMethod, isNull);
    });

    test('awaits an async capability', () async {
      final router = CapabilityRouter([_SlowCapability()]);

      final result = await router.handle({'cap': 'slow', 'method': 'go'});

      expect(result, 'done');
    });

    test('passes empty args when args is missing', () async {
      final cap = FakeCapability('storage');
      final router = CapabilityRouter([cap]);

      await router.handle({'cap': 'storage', 'method': 'keys'});

      expect(cap.lastArgs, isEmpty);
    });

    test('passes empty args when args is not a map', () async {
      final cap = FakeCapability('storage');
      final router = CapabilityRouter([cap]);

      await router.handle({'cap': 'storage', 'method': 'keys', 'args': 5});

      expect(cap.lastArgs, isEmpty);
    });

    test('gives the capability its own copy of args', () async {
      final cap = FakeCapability('storage');
      final router = CapabilityRouter([cap]);
      final args = {'key': 'a'};

      await router.handle({'cap': 'storage', 'method': 'get', 'args': args});
      args['key'] = 'changed';

      expect(cap.lastArgs, {'key': 'a'});
    });

    test('throws StateError for a capability that was not granted', () {
      final router = CapabilityRouter([FakeCapability('storage')]);

      expect(
        () => router.handle({'cap': 'network', 'method': 'fetch'}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Capability not granted: network'),
          ),
        ),
      );
    });

    test('throws ArgumentError when cap is missing or not a string', () {
      final router = CapabilityRouter([FakeCapability('storage')]);

      expect(() => router.handle({'method': 'get'}), throwsArgumentError);
      expect(
        () => router.handle({'cap': 1, 'method': 'get'}),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when method is missing or not a string', () {
      final router = CapabilityRouter([FakeCapability('storage')]);

      expect(() => router.handle({'cap': 'storage'}), throwsArgumentError);
      expect(
        () => router.handle({'cap': 'storage', 'method': 2}),
        throwsArgumentError,
      );
    });

    test('lets capability errors propagate', () {
      final router = CapabilityRouter([_ThrowingCapability()]);

      expect(
        () => router.handle({'cap': 'bad', 'method': 'go'}),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('constructor', () {
    test('rejects duplicate capability names', () {
      expect(
        () => CapabilityRouter([
          FakeCapability('storage'),
          FakeCapability('storage'),
        ]),
        throwsArgumentError,
      );
    });

    test('accepts an empty set, which grants nothing', () {
      final router = CapabilityRouter(const []);

      expect(
        () => router.handle({'cap': 'storage', 'method': 'get'}),
        throwsStateError,
      );
    });
  });
}
