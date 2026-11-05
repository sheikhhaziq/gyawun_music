import 'endpoint.dart';
import 'json_object.dart';
import 'result_types.dart';

/// A named link to another screen, such as an artist or album on an item.
class Ref {
  const Ref({required this.name, this.browse});

  final String name;

  /// Opens the screen for this artist, album or playlist.
  final Endpoint<BrowseResult>? browse;

  factory Ref.parse(JsonObject json) => Ref(
    name: json.string('name'),
    browse: Endpoint.parseOptional<BrowseResult>(
      json.raw('browse'),
      json.pathOf('browse'),
    ),
  );

  static Ref? parseOptional(JsonObject parent, String key) {
    final child = parent.optionalObject(key);
    return child == null ? null : Ref.parse(child);
  }
}
