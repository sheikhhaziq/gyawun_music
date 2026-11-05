import 'package:extension_api/extension_api.dart';

/// A full screen: optional header and chips, then sections.
class BrowseResult {
  const BrowseResult({
    this.header,
    this.chips = const [],
    this.sections = const [],
    this.continuation,
  });

  final Header? header;
  final List<Chip> chips;
  final List<Section> sections;

  /// Loads more sections. Pass it back to `browse`; the response is appended.
  final Endpoint<BrowseResult>? continuation;

  static const maxChips = 50;
  static const maxSections = 100;
  static const maxTotalItems = 2000;

  factory BrowseResult.parse(Object? value, [String path = 'browse']) {
    final json = JsonObject.of(value, path);
    final sections = [
      for (final s in json.objects('sections', max: maxSections))
        Section.parse(s),
    ];
    final total = sections.fold<int>(0, (sum, s) => sum + s.items.length);
    if (total > maxTotalItems) {
      throw FormatException(
        '$path has $total items in total, at most $maxTotalItems allowed',
      );
    }
    return BrowseResult(
      header: Header.parseOptional(json, 'header'),
      chips: List.unmodifiable([
        for (final c in json.objects('chips', max: maxChips)) Chip.parse(c),
      ]),
      sections: List.unmodifiable(sections),
      continuation: Endpoint.parseOptional<BrowseResult>(
        json.raw('continuation'),
        json.pathOf('continuation'),
      ),
    );
  }
}
