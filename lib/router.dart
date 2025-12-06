import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun_music/core/extensions/context_extensions.dart';
import 'package:gyawun_music/core/router/route_paths.dart';
import 'package:gyawun_music/features/library/views/favourites_screen.dart';
import 'package:gyawun_music/features/library/views/history_details.dart';
import 'package:gyawun_music/features/library/views/playlist_details.dart';
import 'package:gyawun_music/features/main/main_screen.dart';
import 'package:gyawun_music/features/onboarding/view/onboarding_screen.dart';
import 'package:gyawun_music/features/player/player_screen.dart';
import 'package:gyawun_music/features/player/queue_screen.dart';
import 'package:gyawun_music/features/player/widgets/bottom_player.dart';
import 'package:gyawun_music/features/services/jio_saavn/album/js_album_screen.dart';
import 'package:gyawun_music/features/services/yt_music/album/yt_album_screen.dart';
import 'package:gyawun_music/features/services/yt_music/artist/yt_artist_screen.dart';
import 'package:gyawun_music/features/services/yt_music/browse/yt_browse_screen.dart';
import 'package:gyawun_music/features/services/yt_music/chip/yt_chip_screen.dart';
import 'package:gyawun_music/features/services/yt_music/playlist/yt_playlist_screen.dart';
import 'package:gyawun_music/features/services/yt_music/podcast/yt_podcast_screen.dart';
import 'package:gyawun_music/features/services/yt_music/search/yt_suggestions_screen.dart';
import 'package:gyawun_music/features/settings/views/about_screen.dart';
import 'package:gyawun_music/features/settings/views/appearance_screen.dart';
import 'package:gyawun_music/features/settings/views/jio_saavn_screen.dart';
import 'package:gyawun_music/features/settings/views/player_screen.dart' as settings;
import 'package:gyawun_music/features/settings/views/privacy_screen.dart';
import 'package:gyawun_music/features/settings/views/storage_screen.dart';
import 'package:gyawun_music/features/settings/views/youtube_music_screen.dart';
import 'package:gyawun_shared/gyawun_shared.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final searchNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'search');
final libraryNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'library');
final settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

Map<String, dynamic> decodedBody(GoRouterState state) =>
    Map<String, dynamic>.from(jsonDecode(Uri.decodeComponent(state.pathParameters['body']!)));

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RoutePaths.onboarding,
  routes: [
    GoRoute(path: RoutePaths.onboarding, builder: (context, state) => const OnboardingScreen()),
    // GoRoute(path: RoutePaths.setup, builder: (context, state) => const SettingUpScreen()),

    /// Main Shell
    ShellRoute(
      builder: (context, state, child) {
        return Stack(children: [child, if (!context.isWideScreen) const BottomPlayer()]);
      },
      routes: [
        GoRoute(
          path: RoutePaths.home,
          builder: (context, state) => const MainScreen(),
          routes: [
            /// ---------- YT MUSIC ROUTES ----------
            GoRoute(
              path: RoutePaths.ytPlaylist,
              builder: (context, state) => YTPlaylistScreen(body: decodedBody(state)),
            ),

            GoRoute(
              path: RoutePaths.ytChip,
              builder: (context, state) => YtChipScreen(
                title: state.pathParameters['title']!,
                type: state.pathParameters['type'] == 'search' ? ChipType.search : ChipType.browse,
                body: decodedBody(state),
              ),
            ),

            GoRoute(
              path: RoutePaths.ytBrowse,
              builder: (context, state) => YTBrowseScreen(body: decodedBody(state)),
            ),

            GoRoute(
              path: RoutePaths.ytBrowseTitle,
              builder: (context, state) =>
                  YTBrowseScreen(body: decodedBody(state), title: state.pathParameters['title']),
            ),

            GoRoute(
              path: RoutePaths.ytAlbum,
              builder: (context, state) => YTAlbumScreen(body: decodedBody(state)),
            ),

            GoRoute(
              path: RoutePaths.jsAlbum,
              builder: (context, state) => JSAlbumScreen(id: state.pathParameters['id']!),
            ),

            GoRoute(
              path: RoutePaths.ytArtist,
              builder: (context, state) => YTArtistScreen(body: decodedBody(state)),
            ),

            GoRoute(
              path: RoutePaths.ytPodcast,
              builder: (context, state) => YTPodcastScreen(body: decodedBody(state)),
            ),

            GoRoute(
              path: RoutePaths.ytSuggestions,
              pageBuilder: (context, state) => CustomTransitionPage(
                child: YTSuggestionsScreen(query: state.uri.queryParameters['q']),
                transitionsBuilder: (context, animation, secondary, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            ),

            /// ---------- LIBRARY ----------
            GoRoute(
              path: RoutePaths.libraryPlaylist,
              builder: (context, state) => PlaylistDetailsScreen(
                name: state.pathParameters['name']!,
                id: state.pathParameters['id']!,
              ),
            ),
            GoRoute(
              path: RoutePaths.libraryHistory,
              builder: (context, state) => const HistoryDetailsScreen(),
            ),
            GoRoute(
              path: RoutePaths.libraryFavourites,
              builder: (context, state) => const FavouritesScreen(),
            ),

            /// ---------- SETTINGS ----------
            GoRoute(
              path: RoutePaths.settingsAppearance,
              builder: (context, state) => const AppearanceScreen(),
            ),
            GoRoute(
              path: RoutePaths.settingsPlayer,
              builder: (context, state) => const settings.PlayerScreen(),
            ),
            GoRoute(
              path: RoutePaths.settingsYtMusic,
              builder: (context, state) => const YoutubeMusicScreen(),
            ),
            GoRoute(
              path: RoutePaths.settingsJioSaavn,
              builder: (context, state) => const JioSaavnScreen(),
            ),
            GoRoute(
              path: RoutePaths.settingsStorage,
              builder: (context, state) => const StorageScreen(),
            ),
            GoRoute(
              path: RoutePaths.settingsPrivacy,
              builder: (context, state) => const PrivacyScreen(),
            ),
            GoRoute(
              path: RoutePaths.settingsAbout,
              builder: (context, state) => const AboutScreen(),
            ),
          ],
        ),
      ],
    ),

    /// PLAYER ROUTES
    GoRoute(
      path: RoutePaths.player,
      pageBuilder: (context, state) =>
          const CupertinoPage(fullscreenDialog: true, child: PlayerScreen()),
      routes: [
        GoRoute(
          path: RoutePaths.queue,
          pageBuilder: (context, state) =>
              const CupertinoPage(fullscreenDialog: true, child: QueueScreen()),
        ),
      ],
    ),
  ],
);
