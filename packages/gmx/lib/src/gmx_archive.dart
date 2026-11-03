import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'layout.dart';
import 'metadata.dart';

/// Limits applied when reading an archive.
class GmxLimits {
  const GmxLimits({
    this.maxArchiveBytes = 10 << 20,
    this.maxTotalBytes = 5 << 20,
    this.maxEntries = 20,
    this.maxEntryScriptBytes = 2 << 20,
    this.maxIconBytes = 100 << 10,
    this.maxDocBytes = 256 << 10,
    this.maxIconDimension = 256,
  });

  final int maxArchiveBytes;
  final int maxTotalBytes;
  final int maxEntries;
  final int maxEntryScriptBytes;
  final int maxIconBytes;
  final int maxDocBytes;
  final int maxIconDimension;

  int maxFor(String name) => switch (name) {
    GmxFiles.metadata => GmxMetadata.maxBytes,
    GmxFiles.entry => maxEntryScriptBytes,
    GmxFiles.icon => maxIconBytes,
    _ => maxDocBytes,
  };
}

/// A fully validated .gmx archive.
class GmxArchive {
  GmxArchive._({
    required this.metadata,
    required this.script,
    required this.icon,
    required this.readme,
    required this.changelog,
    required this.license,
  });

  final GmxMetadata metadata;
  final String script;
  final Uint8List? icon;
  final String? readme;
  final String? changelog;
  final String? license;

  /// Reads and validates [bytes]. Throws [FormatException] on any problem.
  factory GmxArchive.read(
    Uint8List bytes, {
    GmxLimits limits = const GmxLimits(),
  }) {
    if (bytes.length > limits.maxArchiveBytes) {
      throw const FormatException('Archive is too large');
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw FormatException('Not a valid zip archive: $e');
    }

    final files = archive.files.where((f) => f.isFile).toList();
    if (files.length > limits.maxEntries) {
      throw const FormatException('Archive has too many files');
    }

    // Validate names and declared sizes before decompressing anything.
    final seen = <String>{};
    var total = 0;
    for (final file in files) {
      final name = file.name;
      if (!GmxFiles.allowed.contains(name)) {
        throw FormatException('Unexpected file in archive: $name');
      }
      if (!seen.add(name)) {
        throw FormatException('Duplicate file in archive: $name');
      }
      if (file.size > limits.maxFor(name)) {
        throw FormatException('$name is too large');
      }
      total += file.size;
      if (total > limits.maxTotalBytes) {
        throw const FormatException('Archive contents are too large');
      }
    }
    for (final required in GmxFiles.required) {
      if (!seen.contains(required)) {
        throw FormatException('Missing required file: $required');
      }
    }

    Uint8List read(String name) {
      final file = files.firstWhere((f) => f.name == name);
      final data = Uint8List.fromList(file.readBytes() ?? const []);
      // Declared sizes can lie, so check what was actually produced.
      if (data.length != file.size || data.length > limits.maxFor(name)) {
        throw FormatException('$name has an inconsistent size');
      }
      return data;
    }

    String text(String name) {
      try {
        return utf8.decode(read(name));
      } on FormatException {
        throw FormatException('$name is not valid UTF-8');
      }
    }

    String? optionalText(String name) =>
        seen.contains(name) ? text(name) : null;

    Uint8List? icon;
    if (seen.contains(GmxFiles.icon)) {
      icon = read(GmxFiles.icon);
      _checkPng(icon, limits.maxIconDimension);
    }

    return GmxArchive._(
      metadata: GmxMetadata.parse(text(GmxFiles.metadata)),
      script: text(GmxFiles.entry),
      icon: icon,
      readme: optionalText(GmxFiles.readme),
      changelog: optionalText(GmxFiles.changelog),
      license: optionalText(GmxFiles.license),
    );
  }

  static const _pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];

  /// Checks the PNG signature and reads the size from the IHDR chunk.
  static void _checkPng(Uint8List data, int maxDimension) {
    if (data.length < 24 ||
        !_pngSignature.indexed.every((e) => data[e.$1] == e.$2)) {
      throw const FormatException('icon.png is not a PNG image');
    }
    final header = ByteData.sublistView(data);
    final isIhdr = header.getUint32(12) == 0x49484452; // "IHDR"
    final width = header.getUint32(16);
    final height = header.getUint32(20);
    if (!isIhdr || width == 0 || height == 0) {
      throw const FormatException('icon.png has an invalid header');
    }
    if (width > maxDimension || height > maxDimension) {
      throw FormatException(
        'icon.png must be at most ${maxDimension}x$maxDimension',
      );
    }
  }
}
