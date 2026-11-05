import 'package:extension_api/extension_api.dart';

/// A button on a section or header.
///
/// The type decides which extension method the endpoint goes back to:
/// [PlayAction] to `queue`, [BrowseAction] to `items`.
sealed class SectionAction {
  const SectionAction();

  factory SectionAction.parse(JsonObject json) {
    final type = json.string('type', max: 20);
    final endpoint = json.raw('endpoint');
    final path = json.pathOf('endpoint');
    return switch (type) {
      'play' => PlayAction(Endpoint.parse<QueueResult>(endpoint, path)),
      'browse' => BrowseAction(Endpoint.parse<ItemsResult>(endpoint, path)),
      _ => throw FormatException(
        '${json.pathOf('type')} must be "play" or "browse"',
      ),
    };
  }

  static SectionAction? parseOptional(JsonObject parent, String key) {
    final child = parent.optionalObject(key);
    return child == null ? null : SectionAction.parse(child);
  }
}

/// Fetches items and plays them.
final class PlayAction extends SectionAction {
  const PlayAction(this.endpoint);
  final Endpoint<QueueResult> endpoint;
}

/// Opens a screen with a list of items (no sections), maybe with a
/// continuation.
final class BrowseAction extends SectionAction {
  const BrowseAction(this.endpoint);
  final Endpoint<ItemsResult> endpoint;
}
