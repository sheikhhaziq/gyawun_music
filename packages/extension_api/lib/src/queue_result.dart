import 'endpoint.dart';
import 'item.dart';
import 'json_object.dart';

/// Items to play. Every item must be playable.
class QueueResult {
  const QueueResult({this.items = const [], this.continuation});

  final List<Item> items;

  /// For endless radio: pass it back to `queue` for more items.
  final Endpoint<QueueResult>? continuation;

  static const maxItems = 500;

  factory QueueResult.parse(Object? value, [String path = 'queue']) {
    final json = JsonObject.of(value, path);
    final objects = json.objects('items', max: maxItems);
    final items = <Item>[];
    for (final o in objects) {
      final item = Item.parse(o);
      if (!item.kind.isPlayable) {
        throw FormatException(
          '${o.pathOf('kind')} must be song, video or episode in a queue, '
          'got ${item.kind.name}',
        );
      }
      items.add(item);
    }
    return QueueResult(
      items: List.unmodifiable(items),
      continuation: Endpoint.parseOptional<QueueResult>(
        json.raw('continuation'),
        json.pathOf('continuation'),
      ),
    );
  }
}
