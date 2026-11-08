import 'dart:typed_data';

import 'package:extension_repository/extension_repository.dart';
import 'package:gmx/gmx.dart';
import 'package:pub_semver/pub_semver.dart';

import 'archive_downloader.dart';
import 'install_types.dart';
import 'installed_record.dart';
import 'interfaces.dart';

class ExtensionManager {
  ExtensionManager({
    required this._store,
    required this._files,
    required this._downloader,
    required this.supportedApiVersion,
    this._clearStorage,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final InstalledExtensionStore _store;
  final ArchiveFiles _files;
  final ArchiveDownloader _downloader;
  final Future<void> Function(String extensionId)? _clearStorage;
  final DateTime Function() _clock;

  /// The highest extension `apiVersion` this app can run.
  final int supportedApiVersion;

  Future<List<InstalledRecord>> installed() => _store.all();

  /// Installs, or updates, the extension described by [entry].
  ///
  /// Returns the saved record, or null if [confirm] declined. Throws
  /// [InstallException] if a check fails, and lets [ArchiveDownloadException]
  /// from the download propagate.
  ///
  /// An update keeps the `enabled` flag and original install time.
  Future<InstalledRecord?> install(
    RepositoryEntry entry,
    Uri repositoryUrl, {
    required ConfirmInstall confirm,
  }) async {
    final existing = (await _store.all())
        .where((r) => r.id == entry.id)
        .firstOrNull;

    // Cheap checks on the repository's claims, before downloading anything.
    if (existing != null) _requireNewer(existing, entry.semver);
    _requireSupported(entry.apiVersion);

    final bytes = await _downloader.download(entry);
    final archive = _read(bytes);
    final metadata = archive.metadata;

    // The repository is untrusted: the archive decides identity.
    if (metadata.id != entry.id) {
      throw InstallException(
        'Archive id ${metadata.id} does not match ${entry.id}',
      );
    }
    if (metadata.version != entry.version) {
      throw InstallException(
        'Archive version ${metadata.version} does not match ${entry.version}',
      );
    }
    _requireSupported(metadata.apiVersion);

    final previousBytes = existing == null ? null : await _files.read(entry.id);
    final grew =
        existing != null &&
        _permissionsGrew(
          _previousPermissions(previousBytes),
          metadata.permissions,
        );
    final sourceChanged =
        existing != null && existing.repositoryUrl != repositoryUrl;

    if (existing == null || grew || sourceChanged) {
      final approved = await confirm(
        InstallPrompt(
          metadata: metadata,
          installed: existing,
          permissionsGrew: grew,
          sourceChanged: sourceChanged,
        ),
      );
      if (!approved) return null;
    }

    final record = InstalledRecord(
      id: metadata.id,
      version: metadata.version,
      repositoryUrl: repositoryUrl,
      installedAt: existing?.installedAt ?? _clock(),
      enabled: existing?.enabled ?? false,
    );

    await _files.write(entry.id, bytes);
    try {
      await _store.save(record);
    } catch (_) {
      await _restore(entry.id, previousBytes);
      rethrow;
    }
    return record;
  }

  Future<void> uninstall(String id, {bool deleteData = false}) async {
    if (deleteData && _clearStorage == null) {
      throw StateError('No clearStorage callback was configured');
    }
    await _store.delete(id);
    await _files.delete(id);
    if (deleteData) await _clearStorage!(id);
  }

  GmxArchive _read(Uint8List bytes) {
    try {
      return GmxArchive.read(bytes);
    } on FormatException catch (e) {
      throw InstallException('Not a valid extension: ${e.message}');
    }
  }

  void _requireSupported(int apiVersion) {
    if (apiVersion > supportedApiVersion) {
      throw InstallException(
        'Needs extension API $apiVersion, this app supports '
        '$supportedApiVersion. Update the app.',
      );
    }
  }

  void _requireNewer(InstalledRecord existing, Version offered) {
    if (!GmxMetadata.isValidVersion(existing.version)) return;
    final current = Version.parse(existing.version);
    if (offered <= current) {
      throw InstallException(
        'Version $offered is not newer than the installed ${existing.version}',
      );
    }
  }

  /// Null when there is no readable previous archive.
  GmxPermissions? _previousPermissions(Uint8List? bytes) {
    if (bytes == null) return null;
    try {
      return GmxArchive.read(bytes).metadata.permissions;
    } on FormatException {
      return null;
    }
  }

  /// Logging is harmless and ignored. Domains are compared exactly, which is
  /// conservative: a rewritten pattern asks the user again.
  static bool _permissionsGrew(GmxPermissions? old, GmxPermissions now) {
    if (old == null) return true;
    return (now.storage && !old.storage) ||
        !old.networkDomains.toSet().containsAll(now.networkDomains);
  }

  /// Puts the files back the way they were. Best effort: the original error
  /// is the one worth reporting.
  Future<void> _restore(String id, Uint8List? previous) async {
    try {
      if (previous != null) {
        await _files.write(id, previous);
      } else {
        await _files.delete(id);
      }
    } catch (_) {}
  }
}
