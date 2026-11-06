import 'package:pub_semver/pub_semver.dart';

import 'repository_entry.dart';
import 'repository_index.dart';

/// What the app knows about an installed extension.
class InstalledVersion {
  const InstalledVersion({
    required this.id,
    required this.semver,
    required this.repositoryUrl,
  });

  final String id;
  final Version semver;

  /// The repository it was installed from.
  final Uri repositoryUrl;
}

class AvailableUpdate {
  const AvailableUpdate(this.installed, this.entry, {this.repositoryUrl});

  final InstalledVersion installed;
  final RepositoryEntry entry;

  /// Where [entry] comes from. Differs from the installed extension's own
  /// repository only in [UpdateReport.otherSource].
  final Uri? repositoryUrl;
}

class UpdateReport {
  const UpdateReport({
    this.updates = const [],
    this.incompatible = const [],
    this.otherSource = const [],
  });

  /// Newer versions from the same repository that the app can run.
  final List<AvailableUpdate> updates;

  /// Newer versions that need a newer app.
  final List<AvailableUpdate> incompatible;

  /// Newer versions offered only by a different repository. Needs explicit
  /// user consent, so these are never installed as ordinary updates.
  final List<AvailableUpdate> otherSource;
}

UpdateReport findUpdates(
  Iterable<InstalledVersion> installed,
  Map<Uri, RepositoryIndex> indexes, {
  required int supportedApiVersion,
}) {
  final updates = <AvailableUpdate>[];
  final incompatible = <AvailableUpdate>[];
  final otherSource = <AvailableUpdate>[];

  bool isNewer(InstalledVersion current, RepositoryEntry entry) =>
      entry.semver > current.semver &&
      (!entry.semver.isPreRelease || current.semver.isPreRelease);

  for (final current in installed) {
    final own = indexes[current.repositoryUrl]?.find(current.id);
    if (own != null && isNewer(current, own)) {
      final update = AvailableUpdate(
        current,
        own,
        repositoryUrl: current.repositoryUrl,
      );
      (own.apiVersion > supportedApiVersion ? incompatible : updates).add(
        update,
      );
    }

    for (final MapEntry(key: url, value: index) in indexes.entries) {
      if (url == current.repositoryUrl) continue;
      final other = index.find(current.id);
      if (other != null &&
          isNewer(current, other) &&
          other.apiVersion <= supportedApiVersion) {
        otherSource.add(AvailableUpdate(current, other, repositoryUrl: url));
      }
    }
  }

  return UpdateReport(
    updates: List.unmodifiable(updates),
    incompatible: List.unmodifiable(incompatible),
    otherSource: List.unmodifiable(otherSource),
  );
}
