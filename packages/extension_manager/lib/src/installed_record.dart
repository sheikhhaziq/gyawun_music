/// What the app remembers about an installed extension. The archive itself
/// lives in [ArchiveFiles]; the extension's own data lives in its storage.
class InstalledRecord {
  const InstalledRecord({
    required this.id,
    required this.version,
    required this.repositoryUrl,
    required this.installedAt,
    this.enabled = false,
  });

  final String id;

  /// Taken from the archive's metadata, not from the repository.
  final String version;

  /// The repository it was installed from. Updates come from here only.
  final Uri repositoryUrl;

  final DateTime installedAt;
  final bool enabled;

  InstalledRecord copyWith({
    String? version,
    Uri? repositoryUrl,
    DateTime? installedAt,
    bool? enabled,
  }) => InstalledRecord(
    id: id,
    version: version ?? this.version,
    repositoryUrl: repositoryUrl ?? this.repositoryUrl,
    installedAt: installedAt ?? this.installedAt,
    enabled: enabled ?? this.enabled,
  );

  @override
  bool operator ==(Object other) =>
      other is InstalledRecord &&
      other.id == id &&
      other.version == version &&
      other.repositoryUrl == repositoryUrl &&
      other.installedAt == installedAt &&
      other.enabled == enabled;

  @override
  int get hashCode =>
      Object.hash(id, version, repositoryUrl, installedAt, enabled);

  @override
  String toString() => 'InstalledRecord($id $version, enabled: $enabled)';
}
