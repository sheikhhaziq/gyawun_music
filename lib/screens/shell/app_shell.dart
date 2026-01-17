import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navigation_rail_m3e/navigation_rail_m3e.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../generated/l10n.dart';
import '../../utils/bottom_modals.dart';
import '../../utils/check_update.dart';
import 'widgets/bottom_player.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    Key? key,
    required this.navigationShell,
  }) : super(key: key ?? const ValueKey('AppShell'));
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
      _intentSub =
          ReceiveSharingIntent.instance.getMediaStream().listen((value) {
        if (value.isNotEmpty) _handleIntent(value.first);
      });

      ReceiveSharingIntent.instance.getInitialMedia().then((value) {
        if (value.isNotEmpty) _handleIntent(value.first);
        ReceiveSharingIntent.instance.reset();
      });
    }

    _update();
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

  Future<void> _update() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    BaseDeviceInfo deviceInfo = await deviceInfoPlugin.deviceInfo;
    UpdateInfo? updateInfo = await Isolate.run(() async {
      return await checkUpdate(deviceInfo: deviceInfo);
    });

    if (updateInfo != null) {
      if (mounted) {
        Modals.showUpdateDialog(context, updateInfo);
      }
    }
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
                    // backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    // labelType: NavigationRailLabelType.none,
                    // selectedLabelTextStyle: smallTextStyle(context, bold: true),
                    onDestinationSelected: _goBranch,
                    sections: [
                      NavigationRailM3ESection(
                        destinations: [
                          NavigationRailM3EDestination(
                            selectedIcon:
                                const Icon(CupertinoIcons.music_house_fill),
                            icon: const Icon(CupertinoIcons.music_house),
                            label: S.of(context).Home,
                          ),
                          NavigationRailM3EDestination(
                              selectedIcon:
                                  const Icon(Icons.library_music_outlined),
                              icon: const Icon(Icons.library_music_outlined),
                              label: S.of(context).Saved),
                          NavigationRailM3EDestination(
                            selectedIcon:
                                const Icon(CupertinoIcons.gear_alt_fill),
                            icon: const Icon(CupertinoIcons.gear_alt),
                            label: S.of(context).Settings,
                          )
                        ],
                      )
                    ],
                    selectedIndex: widget.navigationShell.currentIndex,
                  ),
                Expanded(
                  child: widget.navigationShell,
                ),
              ],
            ),
          ),
          const BottomPlayer()
        ],
      ),
      bottomNavigationBar: screenWidth < 450
          ? NavigationBar(
              selectedIndex: widget.navigationShell.currentIndex,
              destinations: [
                NavigationDestination(
                  selectedIcon: const Icon(CupertinoIcons.music_house_fill),
                  icon: const Icon(CupertinoIcons.music_house),
                  label: S.of(context).Home,
                ),
                NavigationDestination(
                  selectedIcon: const Icon(Icons.library_music),
                  icon: const Icon(Icons.library_music_outlined),
                  label: S.of(context).Saved,
                ),
                NavigationDestination(
                  selectedIcon: const Icon(CupertinoIcons.settings_solid),
                  icon: const Icon(CupertinoIcons.settings),
                  label: S.of(context).Settings,
                ),
              ],
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerLow,
              // colo: Theme.of(context).colorScheme.onSurface,
              onDestinationSelected: _goBranch,
            )
          : null,
    );
  }
}
