import 'dart:convert';

import 'package:extension_api/extension_api.dart';

import 'repository_entry.dart';

/// A parsed repository file.
class RepositoryIndex {
  const RepositoryIndex({
    this.name,
    this.entries = const [],
    this.problems = const [],
  });

  final String? name;

  /// Valid entries, in file order.
  final List<RepositoryEntry> entries;

  /// Why entries were skipped, for the UI to show. Empty when all were valid.
  final List<String> problems;

  static const supportedSchema = 1;
  static const maxBytes = 2 << 20;
  static const maxEntries = 1000;

  /// Parses the text of a repository file.
  ///
  /// Throws [FormatException] if the file as a whole is unusable (bad JSON,
  /// unsupported schema, `extensions` missing or not a list). A single bad
  /// entry is skipped and reported in [problems] instead.
  factory RepositoryIndex.parse(String source) {
    if (utf8.encode(source).length > maxBytes) {
      throw const FormatException('Repository file is too large');
    }
    final json = JsonObject.of(jsonDecode(source), 'index');

    final schema = json.optionalInt('schema', min: 1, max: 1000000);
    if (schema != supportedSchema) {
      throw FormatException('Unsupported repository schema: $schema');
    }
    if (json.raw('extensions') is! List) {
      throw const FormatException('index.extensions must be a list');
    }

    final entries = <RepositoryEntry>[];
    final problems = <String>[];
    final seen = <String>{};

    for (final object in json.objects('extensions', max: maxEntries)) {
      try {
        final entry = RepositoryEntry.parse(object);
        if (!seen.add(entry.id)) {
          throw FormatException('${object.path} duplicates id ${entry.id}');
        }
        entries.add(entry);
      } on FormatException catch (e) {
        problems.add(e.message);
      }
    }

    return RepositoryIndex(
      name: json.optionalString('name', max: 100),
      entries: List.unmodifiable(entries),
      problems: List.unmodifiable(problems),
    );
  }

  RepositoryEntry? find(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }
}
