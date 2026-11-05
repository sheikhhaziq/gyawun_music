class JsonObject {
  JsonObject._(this._map, this.path);

  factory JsonObject.of(Object? value, String path) {
    if (value is! Map) throw FormatException('$path must be an object');
    return JsonObject._(value, path);
  }

  final Map _map;
  final String path;

  String _at(String key) => '$path.$key';

  String string(String key, {int max = 200}) {
    final value = _map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('${_at(key)} must be a non-empty string');
    }
    if (value.length > max) {
      throw FormatException('${_at(key)} must be at most $max characters');
    }
    return value;
  }

  String? optionalString(String key, {int max = 200}) =>
      _map[key] == null ? null : string(key, max: max);

  JsonObject object(String key) {
    if (_map[key] == null) throw FormatException('${_at(key)} is required');
    return JsonObject.of(_map[key], _at(key));
  }

  JsonObject? optionalObject(String key) =>
      _map[key] == null ? null : JsonObject.of(_map[key], _at(key));

  /// A missing list is empty. Too many entries is an error, not a truncation.
  List<JsonObject> objects(String key, {required int max}) {
    final value = _map[key];
    if (value == null) return const [];
    if (value is! List) throw FormatException('${_at(key)} must be a list');
    if (value.length > max) {
      throw FormatException('${_at(key)} must have at most $max entries');
    }
    return [
      for (var i = 0; i < value.length; i++)
        JsonObject.of(value[i], '${_at(key)}[$i]'),
    ];
  }

  int? optionalInt(String key, {required int min, required int max}) {
    final value = _map[key];
    if (value == null) return null;
    if (value is! int) throw FormatException('${_at(key)} must be an integer');
    if (value < min || value > max) {
      throw FormatException('${_at(key)} must be between $min and $max');
    }
    return value;
  }

  /// Raw value, for opaque data such as endpoints.
  Object? raw(String key) => _map[key];

  /// Path of a child key, for error messages in other parsers.
  String pathOf(String key) => _at(key);
}
