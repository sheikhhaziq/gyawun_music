import 'package:extension_capabilities/extension_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';

class InMemoryStorage implements ExtensionStorage {
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
  late InMemoryStorage store;
  late StorageCapability storage;

  setUp(() {
    store = InMemoryStorage();
    storage = StorageCapability(store, maxKeyLength: 10, maxValueBytes: 20);
  });

  test('is named storage', () {
    expect(storage.name, 'storage');
  });

  group('set and get', () {
    test('stores and returns a value', () async {
      await storage.handle('set', {'key': 'a', 'value': 'hello'});

      expect(await storage.handle('get', {'key': 'a'}), 'hello');
    });

    test('round-trips structured JSON values', () async {
      final roomy = StorageCapability(store); // default 1 MiB limit
      final value = {
        'n': 1,
        'list': [true, null],
      };
      await roomy.handle('set', {'key': 'a', 'value': value});

      expect(await roomy.handle('get', {'key': 'a'}), value);
    });

    test('get returns null for a missing key', () async {
      expect(await storage.handle('get', {'key': 'missing'}), isNull);
    });

    test('set returns null', () async {
      expect(await storage.handle('set', {'key': 'a', 'value': 1}), isNull);
    });

    test('overwrites an existing value', () async {
      await storage.handle('set', {'key': 'a', 'value': 1});
      await storage.handle('set', {'key': 'a', 'value': 2});

      expect(await storage.handle('get', {'key': 'a'}), 2);
    });
  });

  group('remove', () {
    test('deletes a key', () async {
      await storage.handle('set', {'key': 'a', 'value': 1});
      await storage.handle('remove', {'key': 'a'});

      expect(await storage.handle('get', {'key': 'a'}), isNull);
    });

    test('is fine for a missing key', () async {
      await expectLater(storage.handle('remove', {'key': 'x'}), completes);
    });
  });

  group('keys and clear', () {
    test('keys lists stored keys', () async {
      await storage.handle('set', {'key': 'a', 'value': 1});
      await storage.handle('set', {'key': 'b', 'value': 2});

      expect(await storage.handle('keys', {}), unorderedEquals(['a', 'b']));
    });

    test('clear removes everything', () async {
      await storage.handle('set', {'key': 'a', 'value': 1});
      await storage.handle('clear', {});

      expect(await storage.handle('keys', {}), isEmpty);
    });
  });

  group('key validation', () {
    test('rejects a missing key', () async {
      await expectLater(storage.handle('get', {}), throwsArgumentError);
    });

    test('rejects a non-string key', () async {
      await expectLater(storage.handle('get', {'key': 1}), throwsArgumentError);
    });

    test('rejects an empty key', () async {
      await expectLater(
        storage.handle('get', {'key': ''}),
        throwsArgumentError,
      );
    });

    test('rejects a key over the limit', () async {
      await expectLater(
        storage.handle('get', {'key': 'a' * 11}),
        throwsArgumentError,
      );
    });

    test('accepts a key exactly at the limit', () async {
      await expectLater(
        storage.handle('set', {'key': 'a' * 10, 'value': 1}),
        completes,
      );
    });

    test('validates the key for set, remove and get alike', () async {
      for (final method in ['get', 'set', 'remove']) {
        await expectLater(
          storage.handle(method, {'key': '', 'value': 1}),
          throwsArgumentError,
          reason: method,
        );
      }
    });
  });

  group('value size', () {
    test('rejects a value over the limit and stores nothing', () async {
      await expectLater(
        storage.handle('set', {'key': 'a', 'value': 'x' * 30}),
        throwsArgumentError,
      );
      expect(store.data, isEmpty);
    });

    test('accepts a value at the limit', () async {
      // jsonEncode adds 2 quote characters: 18 + 2 = 20 bytes.
      await expectLater(
        storage.handle('set', {'key': 'a', 'value': 'x' * 18}),
        completes,
      );
    });

    test('counts bytes, not characters', () async {
      // Each emoji is 4 bytes in UTF-8, so 5 of them exceed 20 with quotes.
      await expectLater(
        storage.handle('set', {'key': 'a', 'value': '🎵' * 5}),
        throwsArgumentError,
      );
    });

    test('rejects a value that is not JSON-encodable', () async {
      await expectLater(
        storage.handle('set', {'key': 'a', 'value': Object()}),
        throwsA(anything),
      );
      expect(store.data, isEmpty);
    });
  });

  test('rejects an unknown method', () async {
    await expectLater(storage.handle('drop', {}), throwsArgumentError);
  });

  test(
    'the backend decides isolation: separate stores do not share data',
    () async {
      final other = StorageCapability(InMemoryStorage());
      await storage.handle('set', {'key': 'a', 'value': 1});

      expect(await other.handle('get', {'key': 'a'}), isNull);
    },
  );
}
