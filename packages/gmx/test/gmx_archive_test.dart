import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gmx/gmx.dart';

final _metadata = jsonEncode({
  'id': 'com.example.music',
  'name': 'Example',
  'version': '1.0.0',
  'apiVersion': 1,
  'provides': ['browse'],
});

/// A minimal valid PNG header with the given size (enough for our checks).
Uint8List png({int width = 64, int height = 64, int extra = 0}) {
  final data = ByteData(24 + extra);
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];
  for (var i = 0; i < 8; i++) {
    data.setUint8(i, signature[i]);
  }
  data.setUint32(8, 13);
  data.setUint32(12, 0x49484452);
  data.setUint32(16, width);
  data.setUint32(20, height);
  return data.buffer.asUint8List();
}

Uint8List zip(
  Map<String, List<int>> files, {
  List<String> duplicates = const [],
}) {
  final archive = Archive();
  files.forEach((name, content) {
    archive.addFile(ArchiveFile(name, content.length, content));
  });
  for (final name in duplicates) {
    final content = files[name]!;
    archive.addFile(ArchiveFile(name, content.length, content));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

Map<String, List<int>> basic() => {
  'metadata.json': utf8.encode(_metadata),
  'extension.js': utf8.encode('(ctx) => ({})'),
};

GmxArchive read(Uint8List bytes, {GmxLimits limits = const GmxLimits()}) =>
    GmxArchive.read(bytes, limits: limits);

void main() {
  group('valid archives', () {
    test('reads the required files', () {
      final a = read(zip(basic()));

      expect(a.metadata.id, 'com.example.music');
      expect(a.script, '(ctx) => ({})');
      expect(a.icon, isNull);
      expect(a.readme, isNull);
    });

    test('reads every optional file', () {
      final a = read(
        zip({
          ...basic(),
          'icon.png': png(),
          'README.md': utf8.encode('# hi'),
          'CHANGELOG.md': utf8.encode('1.0.0'),
          'LICENSE': utf8.encode('MIT'),
        }),
      );

      expect(a.icon, isNotNull);
      expect(a.readme, '# hi');
      expect(a.changelog, '1.0.0');
      expect(a.license, 'MIT');
    });

    test('preserves unicode text', () {
      final a = read(zip({...basic(), 'README.md': utf8.encode('héllo 🎵')}));

      expect(a.readme, 'héllo 🎵');
    });
  });

  group('structure', () {
    test('rejects bytes that are not a zip', () {
      expect(
        () => read(Uint8List.fromList([1, 2, 3, 4])),
        throwsFormatException,
      );
    });

    test('rejects a missing metadata.json', () {
      final files = basic()..remove('metadata.json');

      expect(() => read(zip(files)), throwsFormatException);
    });

    test('rejects a missing extension.js', () {
      final files = basic()..remove('extension.js');

      expect(() => read(zip(files)), throwsFormatException);
    });

    test('rejects an unexpected file', () {
      expect(
        () => read(zip({...basic(), 'extra.txt': utf8.encode('x')})),
        throwsFormatException,
      );
    });

    for (final name in [
      '../evil.js',
      '/etc/passwd',
      'assets/data.json',
      'sub/extension.js',
      r'..\evil.js',
      'Extension.js',
    ]) {
      test('rejects the name $name', () {
        expect(
          () => read(zip({...basic(), name: utf8.encode('x')})),
          throwsFormatException,
        );
      });
    }

    test('rejects too many entries', () {
      expect(
        () => read(zip(basic()), limits: const GmxLimits(maxEntries: 1)),
        throwsFormatException,
      );
    });
  });

  group('size limits', () {
    test('rejects an archive over the size cap', () {
      expect(
        () => read(zip(basic()), limits: const GmxLimits(maxArchiveBytes: 10)),
        throwsFormatException,
      );
    });

    test('rejects an oversized extension.js', () {
      expect(
        () => read(
          zip({...basic(), 'extension.js': List.filled(200, 97)}),
          limits: const GmxLimits(maxEntryScriptBytes: 100),
        ),
        throwsFormatException,
      );
    });

    test('accepts extension.js exactly at the limit', () {
      expect(
        () => read(
          zip({...basic(), 'extension.js': List.filled(100, 97)}),
          limits: const GmxLimits(maxEntryScriptBytes: 100),
        ),
        returnsNormally,
      );
    });

    test('rejects an oversized doc file', () {
      expect(
        () => read(
          zip({...basic(), 'README.md': List.filled(200, 97)}),
          limits: const GmxLimits(maxDocBytes: 100),
        ),
        throwsFormatException,
      );
    });

    test('rejects when total contents are too large', () {
      expect(
        () => read(
          zip({
            ...basic(),
            'extension.js': List.filled(600, 97),
            'README.md': List.filled(600, 97),
          }),
          limits: const GmxLimits(maxTotalBytes: 1000),
        ),
        throwsFormatException,
      );
    });

    test('a highly compressible bomb is stopped by declared size', () {
      // 5 MB of zeros compresses to a few KB but declares its real size.
      expect(
        () => read(
          zip({...basic(), 'extension.js': List.filled(5 << 20, 0)}),
          limits: const GmxLimits(maxEntryScriptBytes: 1 << 20),
        ),
        throwsFormatException,
      );
    });
  });

  group('content', () {
    test('rejects invalid metadata', () {
      expect(
        () => read(zip({...basic(), 'metadata.json': utf8.encode('{}')})),
        throwsFormatException,
      );
    });

    test('rejects invalid UTF-8 in extension.js', () {
      expect(
        () => read(
          zip({
            ...basic(),
            'extension.js': [0xff, 0xfe, 0xfd],
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid UTF-8 in a doc file', () {
      expect(
        () => read(
          zip({
            ...basic(),
            'README.md': [0xff, 0xfe],
          }),
        ),
        throwsFormatException,
      );
    });
  });

  group('icon', () {
    test('rejects a file that is not a PNG', () {
      expect(
        () => read(
          zip({...basic(), 'icon.png': utf8.encode('not a png at all....')}),
        ),
        throwsFormatException,
      );
    });

    test('rejects a truncated PNG', () {
      expect(
        () => read(zip({...basic(), 'icon.png': png().sublist(0, 10)})),
        throwsFormatException,
      );
    });

    test('accepts exactly 256x256', () {
      expect(
        () => read(zip({...basic(), 'icon.png': png(width: 256, height: 256)})),
        returnsNormally,
      );
    });

    test('rejects 257 pixels wide', () {
      expect(
        () => read(zip({...basic(), 'icon.png': png(width: 257)})),
        throwsFormatException,
      );
    });

    test('rejects 257 pixels tall', () {
      expect(
        () => read(zip({...basic(), 'icon.png': png(height: 257)})),
        throwsFormatException,
      );
    });

    test('rejects a zero dimension', () {
      expect(
        () => read(zip({...basic(), 'icon.png': png(width: 0)})),
        throwsFormatException,
      );
    });

    test('rejects an icon over the byte limit', () {
      expect(
        () => read(
          zip({...basic(), 'icon.png': png(extra: 200)}),
          limits: const GmxLimits(maxIconBytes: 100),
        ),
        throwsFormatException,
      );
    });
  });
}
