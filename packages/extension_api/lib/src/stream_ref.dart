import 'endpoint.dart';
import 'json_object.dart';
import 'result_types.dart';

/// How the app gets audio or video for a playable item.
///
/// An item with no [StreamRef] is resolved by the app, which searches by
/// title, artists, album and duration.
sealed class StreamRef {
  const StreamRef();

  factory StreamRef.parse(JsonObject json) {
    final type = json.string('type', max: 20);
    return switch (type) {
      'endpoint' => EndpointStream(
        Endpoint.parse<StreamResult>(
          json.raw('endpoint'),
          json.pathOf('endpoint'),
        ),
      ),
      'youtube' => YoutubeStream(_videoId(json)),
      _ => throw FormatException(
        '${json.pathOf('type')} must be "endpoint" or "youtube"',
      ),
    };
  }

  static StreamRef? parseOptional(JsonObject parent, String key) {
    final child = parent.optionalObject(key);
    return child == null ? null : StreamRef.parse(child);
  }

  static final _videoIdPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  static String _videoId(JsonObject json) {
    final id = json.string('id', max: 11);
    if (!_videoIdPattern.hasMatch(id)) {
      throw FormatException('${json.pathOf('id')} is not a YouTube video id');
    }
    return id;
  }
}

/// The extension resolves the stream at play time, so expiring URLs work.
final class EndpointStream extends StreamRef {
  const EndpointStream(this.endpoint);
  final Endpoint<StreamResult> endpoint;
}

/// The app resolves this YouTube video id itself.
final class YoutubeStream extends StreamRef {
  const YoutubeStream(this.videoId);
  final String videoId;
}
