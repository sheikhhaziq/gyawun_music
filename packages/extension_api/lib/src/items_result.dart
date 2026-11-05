import 'endpoint.dart';
import 'item.dart';
import 'json_object.dart';

/// A flat list of items, with no sections. Maybe has a continuation.
class ItemsResult {
  const ItemsResult({this.items = const [], this.continuation});

  final List<Item> items;

  /// Pass it back to `items`; the response is appended.
  final Endpoint<ItemsResult>? continuation;

  static const maxItems = 500;

  factory ItemsResult.parse(Object? value, [String path = 'items']) {
    final json = JsonObject.of(value, path);
    return ItemsResult(
      items: List.unmodifiable([
        for (final i in json.objects('items', max: maxItems)) Item.parse(i),
      ]),
      continuation: Endpoint.parseOptional<ItemsResult>(
        json.raw('continuation'),
        json.pathOf('continuation'),
      ),
    );
  }
}
