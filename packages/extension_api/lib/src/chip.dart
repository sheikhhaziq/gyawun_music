import 'package:extension_api/extension_api.dart';

/// A filter or category button. Tapping it loads a new screen.
class Chip {
  const Chip({required this.text, required this.endpoint});

  final String text;
  final Endpoint<BrowseResult> endpoint;

  factory Chip.parse(JsonObject json) => Chip(
    text: json.string('text'),
    endpoint: Endpoint.parse<BrowseResult>(
      json.raw('endpoint'),
      json.pathOf('endpoint'),
    ),
  );
}
