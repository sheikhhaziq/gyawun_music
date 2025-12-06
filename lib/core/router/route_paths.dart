import 'dart:convert';

class RoutePaths {
  static const String onboarding = '/onboarding';
  static const String setup = '/setup';
  static const String home = '/';
  static const String player = '/player';
  static const String queue = 'queue';

  // YT Music
  static const String ytPlaylist = '/ytmusic/playlist/:body';
  static const String ytBrowse = '/ytmusic/browse/:body';
  static const String ytBrowseTitle = '/ytmusic/browse/:body/:title';
  static const String ytAlbum = '/ytmusic/album/:body';
  static const String ytArtist = '/ytmusic/artist/:body';
  static const String ytPodcast = '/ytmusic/podcast/:body';
  static const String ytSuggestions = '/ytmusic/search/suggestions';
  static const String ytChip = '/ytmusic/chip/:body/:title/:type';

  // JioSaavn
  static const String jsAlbum = '/jiosaavn/album/:id';

  // Library
  static const String libraryPlaylist = '/library/playlists/:name/:id';

  static const String libraryHistory = '/library/history';
  static const String libraryFavourites = '/library/favourites';

  // Settings
  static const String settingsAppearance = '/settings/appearance';
  static const String settingsPlayer = '/settings/player';
  static const String settingsYtMusic = '/settings/ytmusic';
  static const String settingsJioSaavn = '/settings/jiosaavn';
  static const String settingsStorage = '/settings/storage';
  static const String settingsPrivacy = '/settings/privacy';
  static const String settingsAbout = '/settings/about';
}

class RouteLocations {
  static String libraryPlaylist(String name, String id) => '/library/playlists/$name/$id';

  static String ytMusicPage(String page, Map<String, dynamic> body) {
    final encoded = Uri.encodeComponent(jsonEncode(body));
    return '/ytmusic/$page/$encoded';
  }

  static String jsAlbum(String id) => '/jiosaavn/album/$id';
}
