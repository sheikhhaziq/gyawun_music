import 'endpoint.dart';
import 'item_kind.dart';
import 'json_object.dart';
import 'ref.dart';
import 'result_types.dart';
import 'stream_ref.dart';
import 'thumbnails.dart';

/// One entry in a section, list or queue.
class Item {
  const Item({
    required this.kind,
    required this.title,
    this.subtitle,
    this.thumbnails,
    this.artists = const [],
    this.album,
    this.playlist,
    this.durationMs,
    this.browse,
    this.play,
    this.radio,
    this.shuffle,
    this.stream,
  });

  final ItemKind kind;
  final String title;
  final String? subtitle;
  final Thumbnails? thumbnails;
  final List<Ref> artists;
  final Ref? album;
  final Ref? playlist;

  /// Used to match the item when the app has to search for a stream.
  final int? durationMs;

  /// Opens this item's own screen.
  final Endpoint<BrowseResult>? browse;

  /// Each returns the items to queue.
  final Endpoint<QueueResult>? play;
  final Endpoint<QueueResult>? radio;
  final Endpoint<QueueResult>? shuffle;

  /// Playable kinds only. Absent means the app resolves it by search.
  final StreamRef? stream;

  static const maxArtists = 20;
  static const maxDurationMs = 7 * 24 * 60 * 60 * 1000;

  factory Item.parse(JsonObject json) {
    final kind = ItemKind.parse(
      json.string('kind', max: 20),
      json.pathOf('kind'),
    );
    final stream = StreamRef.parseOptional(json, 'stream');
    if (stream != null && !kind.isPlayable) {
      throw FormatException(
        '${json.pathOf('stream')} is only allowed on playable items',
      );
    }

    Endpoint<QueueResult>? queue(String key) =>
        Endpoint.parseOptional<QueueResult>(json.raw(key), json.pathOf(key));

    return Item(
      kind: kind,
      title: json.string('title'),
      subtitle: json.optionalString('subtitle', max: 300),
      thumbnails: Thumbnails.parseOptional(json, 'thumbnails'),
      artists: [
        for (final a in json.objects('artists', max: maxArtists)) Ref.parse(a),
      ],
      album: Ref.parseOptional(json, 'album'),
      playlist: Ref.parseOptional(json, 'playlist'),
      durationMs: json.optionalInt('durationMs', min: 0, max: maxDurationMs),
      browse: Endpoint.parseOptional<BrowseResult>(
        json.raw('browse'),
        json.pathOf('browse'),
      ),
      play: queue('play'),
      radio: queue('radio'),
      shuffle: queue('shuffle'),
      stream: stream,
    );
  }
}
