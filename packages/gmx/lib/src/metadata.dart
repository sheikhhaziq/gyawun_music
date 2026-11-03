import 'dart:convert';

import 'package:pub_semver/pub_semver.dart';

/// What an extension asks to be allowed to do.
class GmxPermissions {
  const GmxPermissions({
    this.storage = false,
    this.log = true,
    this.networkDomains = const [],
  });

  final bool storage;

  /// Logging is harmless, so it is on unless explicitly disabled.
  final bool log;

  /// Domain patterns for network access. Empty means no network.
  final List<String> networkDomains;

  bool get network => networkDomains.isNotEmpty;

  /// Context names understood by `buildExtensionScript`.
  Set<String> get granted => {
    if (storage) 'storage',
    if (log) 'log',
    if (network) 'http',
  };

  static const _keys = {'storage', 'log', 'network'};

  // Lowercase host, optional "*." prefix, at least one dot, alphabetic TLD.
  // This also rules out IPs, schemes, ports and paths.
  static final _domain = RegExp(
    r'^(\*\.)?([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$',
  );

  static const maxDomains = 50;

  factory GmxPermissions.fromJson(Object? json) {
    if (json == null) return const GmxPermissions();
    if (json is! Map) {
      throw const FormatException('"permissions" must be an object');
    }
    for (final key in json.keys) {
      if (!_keys.contains(key)) {
        throw FormatException('Unknown permission: $key');
      }
    }

    final storage = json['storage'] ?? false;
    final log = json['log'] ?? true;
    if (storage is! bool) {
      throw const FormatException('"permissions.storage" must be a boolean');
    }
    if (log is! bool) {
      throw const FormatException('"permissions.log" must be a boolean');
    }

    return GmxPermissions(
      storage: storage,
      log: log,
      networkDomains: _domains(json['network']),
    );
  }

  static List<String> _domains(Object? network) {
    if (network == null) return const [];
    if (network is! Map) {
      throw const FormatException('"permissions.network" must be an object');
    }
    for (final key in network.keys) {
      if (key != 'domains') {
        throw FormatException('Unknown network option: $key');
      }
    }
    final raw = network['domains'];
    if (raw is! List || raw.isEmpty) {
      throw const FormatException(
        '"permissions.network.domains" must be a non-empty list',
      );
    }
    if (raw.length > maxDomains) {
      throw FormatException('Too many network domains (max $maxDomains)');
    }

    final result = <String>{}; // a set removes duplicates, keeps order
    for (final item in raw) {
      final domain = item is String ? item.trim().toLowerCase() : null;
      if (domain == null || domain.length > 253 || !_domain.hasMatch(domain)) {
        throw FormatException('Invalid network domain: $item');
      }
      result.add(domain);
    }
    return result.toList();
  }
}

/// The parsed and validated `metadata.json`.
class GmxMetadata {
  const GmxMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.semver,
    required this.apiVersion,
    this.description,
    this.author,
    this.permissions = const GmxPermissions(),
  });

  final String id;
  final String name;

  /// The version exactly as written in metadata.json.
  final String version;

  /// [version] parsed for comparison (updates, downgrade checks).
  final Version semver;

  final int apiVersion;
  final String? description;
  final String? author;
  final GmxPermissions permissions;

  static const maxBytes = 64 * 1024;

  // Reverse-domain style: at least two lowercase segments.
  static final _id = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$');

  // Strict semantic version, e.g. 1.2.3, 1.2.3-beta.1
  static final _version = RegExp(
    r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
    r'(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$',
  );

  /// Parses the text of metadata.json. Throws [FormatException] if invalid.
  factory GmxMetadata.parse(String source) {
    if (utf8.encode(source).length > maxBytes) {
      throw const FormatException('metadata.json is too large');
    }
    return GmxMetadata.fromJson(jsonDecode(source));
  }

  /// Unknown top-level keys are ignored so newer metadata still loads.
  factory GmxMetadata.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('metadata.json must be a JSON object');
    }

    // Identifiers are not trimmed: surrounding whitespace is an error.
    final id = _required(json, 'id', max: 100, trim: false);
    if (!_id.hasMatch(id)) {
      throw const FormatException(
        '"id" must be lowercase reverse-domain style, e.g. com.example.music',
      );
    }

    final version = _required(json, 'version', max: 50, trim: false);
    if (!_version.hasMatch(version)) {
      throw const FormatException('"version" must be a semantic version');
    }

    final apiVersion = json['apiVersion'];
    if (apiVersion is! int || apiVersion < 1) {
      throw const FormatException('"apiVersion" must be an integer >= 1');
    }

    return GmxMetadata(
      id: id,
      name: _required(json, 'name', max: 60),
      version: version,
      // Safe: the strict regex above already passed.
      semver: Version.parse(version),
      apiVersion: apiVersion,
      description: _optional(json, 'description', max: 500),
      author: _optional(json, 'author', max: 100),
      permissions: GmxPermissions.fromJson(json['permissions']),
    );
  }

  static String _required(
    Map json,
    String key, {
    required int max,
    bool trim = true,
  }) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('"$key" must be a non-empty string');
    }
    if (value.length > max) {
      throw FormatException('"$key" must be at most $max characters');
    }
    return trim ? value.trim() : value;
  }

  static String? _optional(Map json, String key, {required int max}) {
    if (json[key] == null) return null;
    return _required(json, key, max: max);
  }
}
