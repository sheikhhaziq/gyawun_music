import 'endpoint.dart';
import 'json_object.dart';
import 'result_types.dart';

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
