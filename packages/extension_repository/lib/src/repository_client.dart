import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'fetch_result.dart';
import 'repository_index.dart';

/// Downloads repository files. This is the app talking to a repository, not
/// an extension, so it has its own timeout and none of the extension rules.
class RepositoryClient {
  RepositoryClient({
    required this._client,
    this.timeout = const Duration(seconds: 20),
    this.maxRedirects = 3,
  });

  final http.Client _client;
  final Duration timeout;
  final int maxRedirects;

  static const _redirects = {301, 302, 303, 307, 308};
  static const _maxEtagLength = 256;

  /// Downloads and parses [url]. Pass the [etag] of the cached copy to get a
  /// [RepositoryNotModified] when nothing changed.
  ///
  /// Throws [RepositoryFetchException] if the download fails, and
  /// [FormatException] if the file is not a valid repository.
  Future<RepositoryFetchResult> fetch(Uri url, {String? etag}) async {
    try {
      return await _fetch(url, etag).timeout(timeout);
    } on TimeoutException {
      throw RepositoryFetchException(
        'Timed out after ${timeout.inMilliseconds} ms',
      );
    } on http.ClientException catch (e) {
      throw RepositoryFetchException('Network error: ${e.message}');
    }
  }

  Future<RepositoryFetchResult> _fetch(Uri url, String? etag) async {
    var uri = url;
    for (var hop = 0; hop <= maxRedirects; hop++) {
      _checkUrl(uri);

      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers['accept'] = 'application/json';
      if (etag != null) request.headers['if-none-match'] = etag;

      final response = await _client.send(request);
      final status = response.statusCode;
      final location = response.headers['location'];

      if (_redirects.contains(status) && location != null) {
        await response.stream.drain<void>();
        uri = uri.resolve(location);
        continue;
      }

      if (status == 304 && etag != null) {
        await response.stream.drain<void>();
        return const RepositoryNotModified();
      }

      if (status != 200) {
        await response.stream.drain<void>();
        throw RepositoryFetchException('HTTP $status from $uri');
      }

      final bytes = await _readLimited(response);
      final source = utf8.decode(bytes); // FormatException if not UTF-8
      final index = RepositoryIndex.parse(source);

      final tag = response.headers['etag'];
      return RepositoryFetched(
        index: index,
        source: source,
        etag: tag != null && tag.length <= _maxEtagLength ? tag : null,
      );
    }
    throw const RepositoryFetchException('Too many redirects');
  }

  /// Every hop must be https, so a redirect can't downgrade the connection.
  void _checkUrl(Uri uri) {
    if (uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      throw RepositoryFetchException('Only https URLs are allowed: $uri');
    }
  }

  Future<Uint8List> _readLimited(http.StreamedResponse response) async {
    const max = RepositoryIndex.maxBytes;
    final declared = response.contentLength;
    if (declared != null && declared > max) {
      await response.stream.drain<void>();
      throw const RepositoryFetchException('Repository file is too large');
    }

    final builder = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      builder.add(chunk);
      if (builder.length > max) {
        throw const RepositoryFetchException('Repository file is too large');
      }
    }
    return builder.takeBytes();
  }
}
