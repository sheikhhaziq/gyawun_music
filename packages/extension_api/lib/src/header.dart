import 'json_object.dart';
import 'section_action.dart';
import 'thumbnails.dart';

/// A labelled button in a header, such as Play or Shuffle.
class HeaderAction {
  const HeaderAction({required this.label, required this.action});

  final String label;
  final SectionAction action;

  factory HeaderAction.parse(JsonObject json) => HeaderAction(
    label: json.string('label', max: 50),
    action: SectionAction.parse(json.object('action')),
  );
}

/// The top of a screen, such as an artist or playlist page.
class Header {
  const Header({
    required this.title,
    this.description,
    this.thumbnails,
    this.actions = const [],
  });

  final String title;
  final String? description;
  final Thumbnails? thumbnails;
  final List<HeaderAction> actions;

  static const maxActions = 5;

  factory Header.parse(JsonObject json) => Header(
    title: json.string('title'),
    description: json.optionalString('description', max: 1000),
    thumbnails: Thumbnails.parseOptional(json, 'thumbnails'),
    actions: List.unmodifiable([
      for (final a in json.objects('actions', max: maxActions))
        HeaderAction.parse(a),
    ]),
  );

  static Header? parseOptional(JsonObject parent, String key) {
    final child = parent.optionalObject(key);
    return child == null ? null : Header.parse(child);
  }
}
