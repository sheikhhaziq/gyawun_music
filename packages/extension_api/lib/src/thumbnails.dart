import 'json_object.dart';

/// Image URLs in up to three sizes. At least one is required.
class Thumbnails {
  const Thumbnails({this.small, this.medium, this.large})
    : assert(small != null || medium != null || large != null);

  final Uri? small;
  final Uri? medium;
  final Uri? large;

  /// Parses [json], which must be a thumbnails object.
  factory Thumbnails.parse(JsonObject json) {
    final small = _url(json, 'small');
    final medium = _url(json, 'medium');
    final large = _url(json, 'large');
    if (small == null && medium == null && large == null) {
      throw FormatException(
        '${json.path} needs at least one of small, medium, large',
      );
    }
    return Thumbnails(small: small, medium: medium, large: large);
  }

  /// Parses the optional object at [key] in [parent].
  static Thumbnails? parseOptional(JsonObject parent, String key) {
    final child = parent.optionalObject(key);
    return child == null ? null : Thumbnails.parse(child);
  }

  /// The smallest available size.
  Uri get smallest => small ?? medium ?? large!;

  /// The largest available size.
  Uri get largest => large ?? medium ?? small!;

  static Uri? _url(JsonObject json, String key) {
    final text = json.optionalString(key, max: 2048);
    if (text == null) return null;
    final uri = Uri.tryParse(text);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw FormatException('${json.pathOf(key)} must be an https URL');
    }
    return uri;
  }
}
