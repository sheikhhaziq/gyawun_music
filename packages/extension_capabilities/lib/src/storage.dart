import 'dart:convert';

import 'capability.dart';

/// Key-value backend for extensions.
abstract interface class ExtensionStorage {
  Future<Object?> get(String key);
  Future<void> set(String key, Object? value);
  Future<void> remove(String key);
  Future<List<String>> keys();
  Future<void> clear();
}

/// Lets an extension use [ExtensionStorage] after validating its input.
class StorageCapability implements Capability {
  StorageCapability(
    this._store, {
    this.maxKeyLength = 256,
    this.maxValueBytes = 1 << 20,
  });

  final ExtensionStorage _store;
  final int maxKeyLength;
  final int maxValueBytes;

  @override
  String get name => 'storage';

  @override
  Future<Object?> handle(String method, Map<String, dynamic> args) async {
    switch (method) {
      case 'get':
        return _store.get(_key(args));
      case 'set':
        final key = _key(args);
        final value = args['value'];
        if (utf8.encode(jsonEncode(value)).length > maxValueBytes) {
          throw ArgumentError('Value exceeds $maxValueBytes bytes');
        }
        await _store.set(key, value);
        return null;
      case 'remove':
        await _store.remove(_key(args));
        return null;
      case 'keys':
        return _store.keys();
      case 'clear':
        await _store.clear();
        return null;
      default:
        throw ArgumentError('Unknown storage method: $method');
    }
  }

  String _key(Map<String, dynamic> args) {
    final key = args['key'];
    if (key is! String || key.isEmpty || key.length > maxKeyLength) {
      throw ArgumentError(
        'Key must be a non-empty string up to $maxKeyLength characters',
      );
    }
    return key;
  }
}
