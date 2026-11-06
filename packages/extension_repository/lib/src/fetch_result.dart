import 'repository_index.dart';

/// Thrown when a repository can't be downloaded (network failure, bad status,
/// forbidden URL, too large, timeout). A downloaded file that is malformed
/// throws a [FormatException] from `RepositoryIndex.parse` instead.
class RepositoryFetchException implements Exception {
  const RepositoryFetchException(this.message);

  final String message;

  @override
  String toString() => 'RepositoryFetchException: $message';
}

sealed class RepositoryFetchResult {
  const RepositoryFetchResult();
}

/// A fresh copy. The app should cache [source] and [etag] together.
final class RepositoryFetched extends RepositoryFetchResult {
  const RepositoryFetched({
    required this.index,
    required this.source,
    this.etag,
  });

  final RepositoryIndex index;

  /// The raw file text, for caching.
  final String source;

  final String? etag;
}

/// The server confirmed the cached copy is still current.
final class RepositoryNotModified extends RepositoryFetchResult {
  const RepositoryNotModified();
}
