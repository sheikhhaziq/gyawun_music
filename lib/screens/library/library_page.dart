import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/core/widgets/expressive_app_bar.dart';
import 'package:gyawun/core/widgets/expressive_list_group.dart';
import 'package:gyawun/core/widgets/expressive_list_tile.dart';
import 'package:gyawun/core/widgets/internet_guard.dart';
import 'package:gyawun/core/utils/service_locator.dart';
import 'package:gyawun/screens/settings/widgets/color_icon.dart';
import '../../../../generated/l10n.dart';
import '../../../../services/library.dart';
import '../../../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../../../utils/bottom_modals.dart';
import '../../utils/playlist_icon_widget.dart';
import '../../utils/playlist_icons.dart';
import 'cubit/library_cubit.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LibraryCubit(sl<LibraryService>())..loadLibrary(),
      child: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, state) {
          return InternetGuard(
            child: Scaffold(
              floatingActionButton: Column(
                mainAxisSize: .min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'import_playlist',
                    onPressed: () {
                      Modals.showImportplaylistModal(context);
                    },
                    child: const Icon(Icons.import_export_rounded),
                  ),
                  SizedBox(height: 8),
                  FloatingActionButton(
                    heroTag: 'create_playlist',

                    onPressed: () {
                      Modals.showCreateplaylistModal(context);
                    },
                    child: const Icon(FluentIcons.add_24_filled),
                  ),
                ],
              ),
              body: switch (state) {
                LibraryLoading() => const Center(child: AdaptiveProgressRing()),
                LibraryError(:final message) => Center(child: Text(message)),
                LibraryLoaded(
                  :final playlists,
                  favourites: final favourites,
                  :final downloadsCount,
                  :final historyCount,
                ) =>
                  _LibraryBody(
                    playlists: playlists,
                    favourites: favourites,
                    downloadsCount: downloadsCount,
                    historyCount: historyCount,
                  ),
              },
            ),
          );
        },
      ),
    );
  }
}

class _LibraryBody extends StatelessWidget {
  const _LibraryBody({
    required this.playlists,
    required this.favourites,
    this.downloadsCount = 0,
    this.historyCount = 0,
  });

  final Map playlists;
  final Map favourites;
  final int downloadsCount;
  final int historyCount;

  @override
  Widget build(BuildContext context) {
    final favSongs = favourites['songs'];
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [ExpressiveAppBar(title: "Library")];
      },
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const .symmetric(vertical: 4, horizontal: 8),
                child: Column(
                  children: [
                    ExpressiveListGroup(
                      title: "Default",
                      children: [
                        ExpressiveListTile(
                          title: Text(S.of(context).Favourites),
                          leading: ColorIcon(
                            icon: FluentIcons.heart_24_filled,
                            boxColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            iconColor: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            size: 30,
                          ),
                          subtitle: Text(S.of(context).nSongs(favSongs.length)),
                          trailing: Icon(FluentIcons.chevron_right_24_filled),
                          onTap: () => context.push('/library/favourites'),
                          onLongPress: () {
                            Modals.showFavouritesBottomModal(
                              context,
                              favourites,
                            );
                          },
                        ),
                        ExpressiveListTile(
                          title: Text(S.of(context).Downloads),
                          leading: ColorIcon(
                            icon: FluentIcons.cloud_arrow_down_24_filled,
                            boxColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            iconColor: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            size: 30,
                          ),
                          subtitle: Text(S.of(context).nSongs(downloadsCount)),
                          trailing: Icon(FluentIcons.chevron_right_24_filled),
                          onTap: () => context.push('/library/downloads'),
                          onLongPress: () {
                            Modals.showDownloadBottomModal(context);
                          },
                        ),
                        ExpressiveListTile(
                          title: Text(S.of(context).History),
                          leading: ColorIcon(
                            icon: FluentIcons.history_24_filled,
                            boxColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            iconColor: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            size: 30,
                          ),
                          subtitle: Text(S.of(context).nSongs(historyCount)),
                          trailing: Icon(FluentIcons.chevron_right_24_filled),
                          onTap: () => context.push('/library/history'),
                        ),
                      ],
                    ),

                    SizedBox(height: 17),
                    if (playlists.isNotEmpty)
                      ExpressiveListGroup(
                        title: "Custom",
                        children: SplayTreeMap.from(playlists)
                            .map((key, item) {
                              if (item == null) {
                                return MapEntry(key, const SizedBox());
                              }
                              return MapEntry(
                                key,
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: ExpressiveListTile(
                                    title: Text(item['title']),
                                    leading: _playlistLeading(
                                      context,
                                      key,
                                      item,
                                    ),
                                    subtitle:
                                        (item['songs'] != null ||
                                            item['isPredefined'])
                                        ? Text(
                                            item['isPredefined'] == true
                                                ? item['subtitle']
                                                : S
                                                      .of(context)
                                                      .nSongs(
                                                        item['songs'].length,
                                                      ),
                                          )
                                        : null,
                                    trailing: Icon(
                                      FluentIcons.chevron_right_24_filled,
                                    ),
                                    onTap: () {
                                      if (item['isPredefined'] == true) {
                                        context.push(
                                          '/browse',
                                          extra: {
                                            'endpoint': item['endpoint']
                                                .cast<String, dynamic>(),
                                          },
                                        );
                                      } else {
                                        context.push(
                                          '/library/playlist_details',
                                          extra: {'playlistkey': key},
                                        );
                                      }
                                    },
                                    onLongPress: () =>
                                        _showPlaylistMenu(context, key, item),
                                  ),
                                ),
                              );
                            })
                            .values
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playlistLeading(BuildContext context, String key, Map item) {
    if (item['isPredefined'] == true) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(item['type'] == 'ARTIST' ? 30 : 8),
        child: CachedNetworkImage(
          imageUrl: item['thumbnails'].first['url'].replaceAll(
            'w540-h225',
            'w60-h60',
          ),
          height: 40,
          width: 40,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: PlaylistIconWidget(
        data: PlaylistIcons.byId(item['iconId']),
        size: 30,
      ),
    );
  }

  void _showPlaylistMenu(BuildContext context, String key, Map item) {
    if (item['videoId'] == null && item['playlistId'] != null) {
      Modals.showPlaylistBottomModal(context, item);
    } else if (item['isPredefined'] == false) {
      Modals.showPlaylistBottomModal(context, {...item, 'playlistId': key});
    }
  }
}
