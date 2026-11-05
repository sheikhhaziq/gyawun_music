import 'item.dart';
import 'json_object.dart';
import 'section_action.dart';
import 'section_style.dart';

/// A titled row or column of items on a screen.
class Section {
  const Section({
    this.title,
    this.style = SectionStyle.horizontal,
    this.action,
    this.items = const [],
  });

  final String? title;
  final SectionStyle style;
  final SectionAction? action;
  final List<Item> items;

  static const maxItems = 200;

  factory Section.parse(JsonObject json) => Section(
    title: json.optionalString('title'),
    style: SectionStyle.parse(json.optionalString('style', max: 20)),
    action: SectionAction.parseOptional(json, 'action'),
    items: List.unmodifiable([
      for (final i in json.objects('items', max: maxItems)) Item.parse(i),
    ]),
  );
}
