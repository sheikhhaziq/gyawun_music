enum ItemKind {
  song,
  video,
  episode,
  podcast,
  album,
  playlist,
  artist;

  /// Kinds a player can play directly.
  bool get isPlayable => this == song || this == video || this == episode;

  /// Unknown kinds are an error: the app can't guess how to treat them.
  static ItemKind parse(String value, String path) =>
      ItemKind.values.asNameMap()[value] ??
      (throw FormatException('$path has an unknown kind: $value'));
}
