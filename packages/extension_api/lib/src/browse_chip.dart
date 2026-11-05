import 'package:extension_api/extension_api.dart';

/// A filter or category button. Tapping it loads a new screen.
class BrowseChip {
  const BrowseChip({required this.text, required this.endpoint});

  final String text;
  final Endpoint<BrowseResult> endpoint;

  factory BrowseChip.parse(JsonObject json) => BrowseChip(
    text: json.string('text'),
    endpoint: Endpoint.parse<BrowseResult>(
      json.raw('endpoint'),
      json.pathOf('endpoint'),
    ),
  );
}
