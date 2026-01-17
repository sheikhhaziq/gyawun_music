import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/screens/browse/browse_page.dart';
import 'package:gyawun/screens/chip/chip_page.dart';
import 'package:gyawun/screens/home/home_page.dart';
import 'package:gyawun/screens/library/downloads/downloading/downloading_page.dart';
import 'package:gyawun/screens/library/downloads/downloads_page.dart';
import 'package:gyawun/screens/library/downloads/playlist/download_playlist_page.dart';
import 'package:gyawun/screens/library/favourites/favourites_page.dart';
import 'package:gyawun/screens/library/history/history_page.dart';
import 'package:gyawun/screens/library/library_page.dart';
import 'package:gyawun/screens/library/playlist/playlist_details_page.dart';
import 'package:gyawun/screens/player/player_page.dart';
import 'package:gyawun/screens/search/search_page.dart';
import 'package:gyawun/screens/settings/about/about_page.dart';
import 'package:gyawun/screens/settings/appearance/appearance_page.dart';
import 'package:gyawun/screens/settings/backup_storage/backup_storage_page.dart';
import 'package:gyawun/screens/settings/player/equalizer/equalizer_page.dart';
import 'package:gyawun/screens/settings/player/player_settings_page.dart';
import 'package:gyawun/screens/settings/privacy/privacy_page.dart';
import 'package:gyawun/screens/settings/services/yt_music/yt_music_page.dart';
import 'package:gyawun/screens/settings/settings_page.dart';
import 'package:gyawun/screens/shell/app_shell.dart';

GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => child,
      routes: [
        StatefulShellRoute(
          branches: branches,
          builder: (context, state, navigationShell) => AppShell(
            navigationShell: navigationShell,
          ),
          navigatorContainerBuilder: (context, navigationShell, children) =>
              MyPageView(
            currentIndex: navigationShell.currentIndex,
            children: children,
          ),
        ),
        GoRoute(
          path: '/player',
          pageBuilder: (context, state) {
            final videoId = state.extra as String?;
            return CustomTransitionPage(
              key: state.pageKey,
              child: PlayerPage(videoId: videoId),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                final curve = Curves.ease;
                final tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            );
          },
        ),
      ],
    ),
  ],
);

List<StatefulShellBranch> branches = [
  StatefulShellBranch(
    routes: [
      GoRoute(
          path: '/',
          builder: (context, state) => const HomePage(),
          routes: [
            GoRoute(
              path: 'chip',
              builder: (context, state) {
                Map<String, dynamic> args = state.extra as Map<String, dynamic>;
                return ChipPage(
                    title: args['title'] ?? '',
                    endpoint: args['endpoint'] ?? {});
              },
            ),
            GoRoute(
              path: 'browse',
              builder: (context, state) {
                final args = state.extra as Map<String, dynamic>? ?? {};
                return BrowsePage(
                  endpoint: args['endpoint'] as Map<String, dynamic>,
                  isMore: args['isMore'] as bool? ?? false,
                );
              },
            ),
            GoRoute(
              path: 'search',
              builder: (context, state) {
                final args = state.extra as Map<String, dynamic>?;
                return SearchPage(
                  endpoint: args?['endpoint'] as Map<String, dynamic>?,
                  isMore: args?['isMore'] as bool? ?? false,
                );
              },
            ),
          ]),
    ],
  ),
  StatefulShellBranch(routes: [
    GoRoute(
      path: '/saved',
      builder: (context, state) => const LibraryPage(),
      routes: [
        GoRoute(
          path: 'favourites_page',
          builder: (context, state) => const FavouritesPage(),
        ),
        GoRoute(
          path: 'downloads_page',
          builder: (context, state) => const DownloadsPage(),
          routes: [
            GoRoute(
              path: 'download_playlist_page',
              builder: (context, state) {
                final args = state.extra as Map<String, dynamic>;
                return DownloadPlaylistPage(
                  playlistId: args['playlistId'] as String,
                );
              },
            ),
            GoRoute(
              path: 'downloading_page',
              builder: (context, state) => const DownloadingPage(),
            ),
          ],
        ),
        GoRoute(
          path: 'history_page',
          builder: (context, state) => const HistoryPage(),
        ),
        GoRoute(
          path: 'playlist_details',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>;
            return PlaylistDetailsPage(
              playlistkey: args['playlistkey'] as String,
            );
          },
        ),
      ],
    ),
  ]),
  StatefulShellBranch(routes: [
    GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
        routes: [
          GoRoute(
            path: 'appearance',
            builder: (context, state) => const AppearancePage(),
          ),
          GoRoute(
              path: 'player',
              builder: (context, state) => const PlayerSettingsPage(),
              routes: [
                GoRoute(
                  path: 'equalizer',
                  builder: (context, state) => const EqualizerPage(),
                )
              ]),
          GoRoute(
            path: 'services/ytmusic',
            builder: (context, state) => const YTMusicPage(),
          ),
          GoRoute(
            path: 'backup_storage',
            builder: (context, state) => const BackupStoragePage(),
          ),
          GoRoute(
            path: 'privacy',
            builder: (context, state) => const PrivacyPage(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutPage(),
          ),
        ]),
  ])
];

class MyPageView extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const MyPageView(
      {super.key, required this.currentIndex, required this.children});

  @override
  MyPageViewState createState() => MyPageViewState();
}

class MyPageViewState extends State<MyPageView> {
  final PageController controller = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MyPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      controller.animateToPage(widget.currentIndex,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      scrollDirection:
          (Platform.isWindows || MediaQuery.of(context).size.width >= 450)
              ? Axis.vertical
              : Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      controller: controller,
      children: widget.children,
    );
  }
}
