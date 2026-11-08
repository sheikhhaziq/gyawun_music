import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:extension_repository/extension_repository.dart';
import 'package:http/http.dart' as http;

class ArchiveDownloadException implements Exception {
  const ArchiveDownloadException(this.message);

  final String message;

  @override
  String toString() => 'ArchiveDownloadException: $message';
}

/// Downloads a .gmx and checks it against what the repository claimed.
/// This is the app talking to a server, not an extension, so it has its own
/// timeout.
class ArchiveDownloader {
  ArchiveDownloader({
    required this._client,
    this.timeout = const Duration(seconds: 60),
    this.maxRedirects = 3,
  });

  final http.Client _client;
  final Duration timeout;
  final int maxRedirects;

  static const _redirects = {301, 302, 303, 307, 308};

  /// Returns the archive bytes, verified for size and SHA-256. The bytes are
  /// still untrusted until `GmxArchive.read` has validated them.
  Future<Uint8List> download(RepositoryEntry entry) async {
    try {
      return await _download(entry).timeout(timeout);
    } on TimeoutException {
      throw ArchiveDownloadException(
        'Timed out after ${timeout.inMilliseconds} ms',
      );
    } on http.ClientException catch (e) {
      throw ArchiveDownloadException('Network error: ${e.message}');
    }
  }

  Future<Uint8List> _download(RepositoryEntry entry) async {
    var uri = entry.download;
    for (var hop = 0; hop <= maxRedirects; hop++) {
      if (uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty) {
        throw ArchiveDownloadException('Only https URLs are allowed: $uri');
      }

      final request = http.Request('GET', uri)..followRedirects = false;
      final response = await _client.send(request);
      final location = response.headers['location'];

      if (_redirects.contains(response.statusCode) && location != null) {
        await response.stream.drain<void>();
        uri = uri.resolve(location);
        continue;
      }
      if (response.statusCode != 200) {
        await response.stream.drain<void>();
        throw ArchiveDownloadException('HTTP ${response.statusCode} from $uri');
      }
      return _verify(entry, await _read(response, entry.size));
    }
    throw const ArchiveDownloadException('Too many redirects');
  }

  /// Stops as soon as more than [limit] bytes arrive.
  Future<Uint8List> _read(http.StreamedResponse response, int limit) async {
    final declared = response.contentLength;
    if (declared != null && declared > limit) {
      await response.stream.drain<void>();
      throw const ArchiveDownloadException('Archive is larger than declared');
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      builder.add(chunk);
      if (builder.length > limit) {
        throw const ArchiveDownloadException('Archive is larger than declared');
      }
    }
    return builder.takeBytes();
  }

  Uint8List _verify(RepositoryEntry entry, Uint8List bytes) {
    if (bytes.length != entry.size) {
      throw ArchiveDownloadException(
        'Archive size is ${bytes.length}, expected ${entry.size}',
      );
    }
    if (sha256.convert(bytes).toString() != entry.sha256) {
      throw const ArchiveDownloadException('SHA-256 does not match');
    }
    return bytes;
  }
}
