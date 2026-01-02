import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/screens/saved_screen/download_details_screen.dart';
import 'package:gyawun/screens/saved_screen/download_screen.dart';
import 'package:gyawun/screens/saved_screen/downloading_screen.dart';
import 'package:gyawun/screens/saved_screen/favourite_details_screen.dart';
import 'package:gyawun/screens/saved_screen/history_screen.dart';
import 'package:gyawun/screens/saved_screen/playlist_details_screen.dart';
import 'package:gyawun/screens/settings_screen/privacy/privacy_screen.dart';

import '../screens/home_screen/chip_screen.dart';
import '../screens/home_screen/home_screen.dart';
import '../screens/home_screen/search_screen/search_screen.dart';
import '../screens/saved_screen/saved_screen.dart';
import '../screens/main_screen/main_screen.dart';
import '../screens/main_screen/player_screen.dart';
import '../screens/browse_screen/browse_screen.dart';
import '../screens/settings_screen/about/about_screen.dart';
import '../screens/settings_screen/appearence/appearence_screen.dart';
import '../screens/settings_screen/storage/backup_storage_screen.dart';
import '../screens/settings_screen/services/ytmusic.dart';
import '../screens/settings_screen/player/player_screen.dart';
import '../screens/settings_screen/player/equalizer_screen.dart';
import '../screens/settings_screen/settings_screen.dart';

GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => child,
      routes: [
        StatefulShellRoute(
          branches: branches,
          builder: (context, state, navigationShell) => MainScreen(
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
              child: PlayerScreen(videoId: videoId),
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
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'chip',
              builder: (context, state) {
                Map<String, dynamic> args = state.extra as Map<String, dynamic>;
                return ChipScreen(
                    title: args['title'] ?? '',
                    endpoint: args['endpoint'] ?? {});
              },
            ),
            GoRoute(
              path: 'browse',
              builder: (context, state) {
                final args = state.extra as Map<String, dynamic>? ?? {};
                return BrowseScreen(
                  endpoint: args['endpoint'] as Map<String, dynamic>,
                  isMore: args['isMore'] as bool? ?? false,
                );
              },
            ),
            GoRoute(
              path: 'search',
              builder: (context, state) {
                final args = state.extra as Map<String, dynamic>?;
                return SearchScreen(
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
      builder: (context, state) => const SavedScreen(),
      routes: [
        GoRoute(
          path: 'favourite_details',
          builder: (context, state) => const FavouriteDetailsScreen(),
        ),
        GoRoute(
          path: 'downloads',
          builder: (context, state) => const DownloadScreen(),
          routes: [
            GoRoute(
              path: 'download_details',
              builder: (context, state) {
                final args = state.extra as Map<String, dynamic>;
                return DownloadDetailsScreen(
                  playlistId: args['playlistId'] as String,
                );
              },
            ),
            GoRoute(
              path: 'downloading',
              builder: (context, state) => const DownloadingScreen(),
            ),
          ],
        ),
        GoRoute(
          path: 'history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: 'playlist_details',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>;
            return PlaylistDetailsScreen(
              playlistkey: args['playlistkey'] as String,
            );
          },
        ),
      ],
    ),
  ]),
  // StatefulShellBranch(routes: [
  //   GoRoute(
  //     path: '/ytmusic',
  //     builder: (context, state) => const YTMScreen(),
  //   ),
  // ]),
  StatefulShellBranch(routes: [
    GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          // GoRoute(
          //   path: 'account',
          //   pageBuilder: (context, state) => Platform.isWindows
          //       ? const FluentPage(child: AccountScreen())
          //       : const CupertinoPage(child: AccountScreen()),
          // ),
          GoRoute(
            path: 'appearence',
            builder: (context, state) => const AppearenceScreen(),
          ),
          GoRoute(
            path: 'ytmusic',
            builder: (context, state) => const YtMusicScreen(),
          ),
          GoRoute(
              path: 'player',
              builder: (context, state) => const PlayerSettingsScreen(),
              routes: [
                GoRoute(
                  path: 'equalizer',
                  builder: (context, state) => const EqualizerScreen(),
                )
              ]),
          GoRoute(
            path: 'backup_storage',
            builder: (context, state) => const BackupStorageScreen(),
          ),
          GoRoute(
            path: 'privacy',
            builder: (context, state) => const PrivacyScreen(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutScreen(),
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
