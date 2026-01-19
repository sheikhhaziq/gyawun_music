import 'dart:async';
import 'dart:io';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/services/update_service/update_service.dart';
import 'package:navigation_rail_m3e/navigation_rail_m3e.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../generated/l10n.dart';
import 'widgets/bottom_player.dart';

class AppShell extends StatefulWidget {
  const AppShell({Key? key, required this.navigationShell})
    : super(key: key ?? const ValueKey('AppShell'));
  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late StreamSubscription _intentSub;
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((
        value,
      ) {
        if (value.isNotEmpty) _handleIntent(value.first);
      });

      ReceiveSharingIntent.instance.getInitialMedia().then((value) {
        if (value.isNotEmpty) _handleIntent(value.first);
        ReceiveSharingIntent.instance.reset();
      });
    }

    UpdateService.autoCheck(context);
  }

  void _handleIntent(SharedMediaFile value) {
    if (value.mimeType == 'text/plain' &&
        value.path.contains('music.youtube.com')) {
      Uri? uri = Uri.tryParse(value.path);
      if (uri != null) {
        if (uri.pathSegments.first == 'watch' &&
            uri.queryParameters['v'] != null) {
          context.push('/player', extra: uri.queryParameters['v']);
        } else if (uri.pathSegments.first == 'playlist' &&
            uri.queryParameters['list'] != null) {
          String id = uri.queryParameters['list']!;
          context.push(
            '/browse',
            extra: {
              'endpoint': {'browseId': id.startsWith('VL') ? id : 'VL$id'},
            },
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                if (screenWidth >= 450)
                  NavigationRailM3E(
                    type: screenWidth > 1000
                        ? NavigationRailM3EType.expanded
                        : NavigationRailM3EType.collapsed,
                    onDestinationSelected: _goBranch,
                    sections: [
                      NavigationRailM3ESection(
                        destinations: [
                          NavigationRailM3EDestination(
                            selectedIcon: const Icon(
                              FluentIcons.home_24_filled,
                            ),
                            icon: const Icon(FluentIcons.home_24_regular),
                            label: S.of(context).Home,
                          ),
                          NavigationRailM3EDestination(
                            selectedIcon: const Icon(
                              FluentIcons.library_24_filled,
                            ),
                            icon: const Icon(FluentIcons.library_24_regular),
                            label: 'Library',
                          ),
                          NavigationRailM3EDestination(
                            selectedIcon: const Icon(
                              FluentIcons.settings_24_filled,
                            ),
                            icon: const Icon(FluentIcons.settings_24_regular),
                            label: S.of(context).Settings,
                          ),
                        ],
                      ),
                    ],
                    selectedIndex: widget.navigationShell.currentIndex,
                  ),
                Expanded(child: widget.navigationShell),
              ],
            ),
          ),
          const BottomPlayer(),
        ],
      ),
      bottomNavigationBar: screenWidth < 450
          ? NavigationBar(
              selectedIndex: widget.navigationShell.currentIndex,
              labelBehavior: .onlyShowSelected,
              destinations: [
                NavigationDestination(
                  selectedIcon: const Icon(FluentIcons.home_24_filled),
                  icon: const Icon(FluentIcons.home_24_regular),
                  label: S.of(context).Home,
                ),
                NavigationDestination(
                  selectedIcon: const Icon(FluentIcons.library_24_filled),
                  icon: const Icon(FluentIcons.library_24_regular),
                  label: 'Library',
                ),
                NavigationDestination(
                  selectedIcon: const Icon(FluentIcons.settings_24_filled),
                  icon: const Icon(FluentIcons.settings_24_regular),
                  label: S.of(context).Settings,
                ),
              ],
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerLow,
              // colo: Theme.of(context).colorScheme.onSurface,
              onDestinationSelected: _goBranch,
            )
          : null,
    );
  }
}
