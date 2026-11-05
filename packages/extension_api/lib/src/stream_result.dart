import 'json_object.dart';

/// One playable URL for an item.
class StreamSource {
  const StreamSource({
    required this.url,
    this.mimeType,
    this.bitrate,
    this.headers = const {},
  });

  final Uri url;
  final String? mimeType;

  /// Bits per second.
  final int? bitrate;

  /// Only [allowedHeaders]. Names are lowercase.
  final Map<String, String> headers;

  static const allowedHeaders = {'user-agent', 'referer', 'origin'};
  static const maxHeaderValue = 500;
  static const maxBitrate = 10000000;

  static final _unsafe = RegExp(r'[\r\n\x00]');

  factory StreamSource.parse(JsonObject json) {
    final raw = json.stringMap(
      'headers',
      maxEntries: allowedHeaders.length,
      maxValue: maxHeaderValue,
    );
    final headers = <String, String>{};
    for (final entry in raw.entries) {
      final name = entry.key.toLowerCase();
      if (!allowedHeaders.contains(name)) {
        throw FormatException(
          '${json.pathOf('headers')}.${entry.key} is not an allowed header',
        );
      }
      if (_unsafe.hasMatch(entry.value)) {
        throw FormatException(
          '${json.pathOf('headers')}.${entry.key} has invalid characters',
        );
      }
      if (headers.containsKey(name)) {
        throw FormatException(
          '${json.pathOf('headers')} has a duplicate header: $name',
        );
      }
      headers[name] = entry.value;
    }

    return StreamSource(
      url: json.httpsUri('url', max: 4096),
      mimeType: json.optionalString('mimeType', max: 100),
      bitrate: json.optionalInt('bitrate', min: 1, max: maxBitrate),
      headers: Map.unmodifiable(headers),
    );
  }
}

/// What `getStream` returns: the URLs to play, and when they stop working.
class StreamResult {
  const StreamResult({required this.sources, this.expiresInSeconds});

  final List<StreamSource> sources;

  /// Relative on purpose: the device clock may be wrong and the extension has
  /// no reliable "now". The app turns it into a deadline on arrival.
  /// Null means the URLs do not expire.
  final int? expiresInSeconds;

  static const maxSources = 10;
  static const maxExpirySeconds = 7 * 24 * 60 * 60;

  factory StreamResult.parse(Object? value, [String path = 'stream']) {
    final json = JsonObject.of(value, path);
    final sources = [
      for (final s in json.objects('sources', max: maxSources))
        StreamSource.parse(s),
    ];
    if (sources.isEmpty) {
      throw FormatException('${json.pathOf('sources')} must not be empty');
    }
    return StreamResult(
      sources: List.unmodifiable(sources),
      expiresInSeconds: json.optionalInt(
        'expiresInSeconds',
        min: 1,
        max: maxExpirySeconds,
      ),
    );
  }
}
