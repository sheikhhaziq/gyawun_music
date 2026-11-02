import 'package:extension_capabilities/extension_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';

typedef Entry = ({String id, LogLevel level, String message});

void main() {
  late List<Entry> entries;
  late LoggingCapability logging;

  setUp(() {
    entries = [];
    logging = LoggingCapability(
      extensionId: 'com.example.music',
      sink: (id, level, message) =>
          entries.add((id: id, level: level, message: message)),
      maxMessageLength: 10,
    );
  });

  test('is named logging', () {
    expect(logging.name, 'logging');
  });

  group('write', () {
    test('sends the entry to the sink', () {
      logging.handle('write', {'level': 'warn', 'message': 'careful'});

      expect(entries, hasLength(1));
      expect(entries.single.level, LogLevel.warn);
      expect(entries.single.message, 'careful');
    });

    test('tags the entry with the extension id', () {
      logging.handle('write', {'level': 'info', 'message': 'hi'});

      expect(entries.single.id, 'com.example.music');
    });

    test('ignores an id sent by JS', () {
      logging.handle('write', {
        'level': 'info',
        'message': 'hi',
        'extensionId': 'com.evil.other',
      });

      expect(entries.single.id, 'com.example.music');
    });

    test('accepts every level', () {
      for (final level in LogLevel.values) {
        logging.handle('write', {'level': level.name, 'message': 'x'});
      }

      expect(entries.map((e) => e.level), LogLevel.values);
    });

    test('falls back to info for an unknown level', () {
      logging.handle('write', {'level': 'loud', 'message': 'x'});

      expect(entries.single.level, LogLevel.info);
    });

    test('falls back to info when the level is missing', () {
      logging.handle('write', {'message': 'x'});

      expect(entries.single.level, LogLevel.info);
    });

    test('returns null', () {
      expect(logging.handle('write', {'message': 'x'}), isNull);
    });

    test('logs each call separately, in order', () {
      logging.handle('write', {'message': 'one'});
      logging.handle('write', {'message': 'two'});

      expect(entries.map((e) => e.message), ['one', 'two']);
    });
  });

  group('message length', () {
    test('keeps a message exactly at the limit', () {
      logging.handle('write', {'message': 'a' * 10});

      expect(entries.single.message, 'a' * 10);
    });

    test('truncates a message over the limit and marks it', () {
      logging.handle('write', {'message': 'a' * 11});

      expect(entries.single.message, '${'a' * 10}…');
    });

    test('truncates a very long message', () {
      logging.handle('write', {'message': 'a' * 100000});

      expect(entries.single.message.length, 11);
    });
  });

  group('message conversion', () {
    test('converts a non-string message to text', () {
      logging.handle('write', {'message': 42});

      expect(entries.single.message, '42');
    });

    test('a missing message becomes the text "null"', () {
      logging.handle('write', {});

      expect(entries.single.message, 'null');
    });
  });

  test('rejects an unknown method', () {
    expect(() => logging.handle('read', {}), throwsArgumentError);
    expect(entries, isEmpty);
  });

  test('lets a throwing sink propagate', () {
    final broken = LoggingCapability(
      extensionId: 'x',
      sink: (_, _, _) => throw StateError('disk full'),
    );

    expect(() => broken.handle('write', {'message': 'x'}), throwsStateError);
  });
}
