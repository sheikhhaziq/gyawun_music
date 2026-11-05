import 'dart:convert';

/// Opaque data owned by the extension. The app never inspects it, it only
/// stores it and passes it back to the extension.
class Endpoint<R> {
  const Endpoint._(this.data);

  /// Cap on the encoded JSON size. Continuation tokens are usually 100 to
  /// 1,500 characters, but endpoints may bundle several fields, so this leaves
  /// headroom while still bounding memory.
  static const maxBytes = 16 * 1024;

  final Object data;

  static Endpoint<R> parse<R>(Object? value, String path) {
    if (value == null) throw FormatException('$path must not be null');
    final String encoded;
    try {
      encoded = jsonEncode(value);
    } on Object {
      throw FormatException('$path must be JSON');
    }
    if (utf8.encode(encoded).length > maxBytes) {
      throw FormatException('$path must be at most $maxBytes bytes');
    }
    return Endpoint<R>._(value);
  }

  static Endpoint<R>? parseOptional<R>(Object? value, String path) =>
      value == null ? null : parse<R>(value, path);

  /// What to pass back to the extension.
  Object toJson() => data;
}
