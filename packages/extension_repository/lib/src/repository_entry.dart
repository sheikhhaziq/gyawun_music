import 'package:extension_api/extension_api.dart';
import 'package:gmx/gmx.dart';
import 'package:pub_semver/pub_semver.dart';

/// One extension offered by a repository (its latest version).
///
/// Everything here is a claim by the repository. Identity and permissions
/// are verified against the downloaded archive before installing.
class RepositoryEntry {
  const RepositoryEntry({
    required this.id,
    required this.name,
    required this.version,
    required this.semver,
    required this.apiVersion,
    required this.download,
    required this.sha256,
    required this.size,
    this.description,
    this.author,
    this.icon,
  });

  final String id;
  final String name;
  final String version;
  final Version semver;
  final int apiVersion;
  final Uri download;

  /// Lowercase hex SHA-256 of the .gmx file.
  final String sha256;

  /// Size of the .gmx file in bytes.
  final int size;

  final String? description;
  final String? author;
  final Uri? icon;

  static const maxSize = 10 << 20;
  static final _sha256 = RegExp(r'^[0-9a-f]{64}$');

  factory RepositoryEntry.parse(JsonObject json) {
    final id = json.string('id', max: 100);
    if (!GmxMetadata.isValidId(id)) {
      throw FormatException('${json.pathOf('id')} is not a valid extension id');
    }

    final version = json.string('version', max: 50);
    if (!GmxMetadata.isValidVersion(version)) {
      throw FormatException(
        '${json.pathOf('version')} must be a semantic version',
      );
    }

    final apiVersion = json.optionalInt('apiVersion', min: 1, max: 1000000);
    if (apiVersion == null) {
      throw FormatException('${json.pathOf('apiVersion')} is required');
    }

    final sha256 = json.string('sha256', max: 64);
    if (!_sha256.hasMatch(sha256)) {
      throw FormatException(
        '${json.pathOf('sha256')} must be 64 lowercase hex characters',
      );
    }

    final size = json.optionalInt('size', min: 1, max: maxSize);
    if (size == null) {
      throw FormatException('${json.pathOf('size')} is required');
    }

    return RepositoryEntry(
      id: id,
      name: json.string('name', max: 60),
      version: version,
      semver: Version.parse(version),
      apiVersion: apiVersion,
      download: json.httpsUri('download'),
      sha256: sha256,
      size: size,
      description: json.optionalString('description', max: 200),
      author: json.optionalString('author', max: 100),
      icon: json.optionalHttpsUri('icon'),
    );
  }
}
