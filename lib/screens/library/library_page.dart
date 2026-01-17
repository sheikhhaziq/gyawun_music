import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/core/utils/service_locator.dart';
import 'package:gyawun/utils/extensions.dart';
import 'package:gyawun/utils/internet_guard.dart';
import 'package:gyawun/utils/playlist_thumbnail.dart';

import '../../../../generated/l10n.dart';
import '../../../../services/library.dart';
import '../../../../themes/colors.dart';
import '../../../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../../../utils/bottom_modals.dart';
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
              appBar: AppBar(
                title: Text(S.of(context).Saved),
                centerTitle: true,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () {
                      Modals.showImportplaylistModal(context);
                    },
                    icon: const Icon(
                      Icons.import_export_outlined,
                      size: 25,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Modals.showCreateplaylistModal(context);
                    },
                    icon: const Icon(
                      Icons.add,
                      size: 25,
                    ),
                  ),
                ],
              ),
              body: switch (state) {
                LibraryLoading() => const Center(child: AdaptiveProgressRing()),
                LibraryError(:final message) => Center(child: Text(message)),
                LibraryLoaded(
                  :final playlists,
                  :final favouritesCount,
                  :final downloadsCount,
                  :final historyCount
                ) =>
                  _LibraryBody(
                    playlists: playlists,
                    favouritesCount: favouritesCount,
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
  const _LibraryBody(
      {required this.playlists,
      this.favouritesCount = 0,
      this.downloadsCount = 0,
      this.historyCount = 0});

  final Map playlists;
  final int favouritesCount;
  final int downloadsCount;
  final int historyCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              /// FAVOURITES
              AdaptiveListTile(
                margin: const EdgeInsets.symmetric(vertical: 4),
                title: Text(S.of(context).Favourites),
                leading: _iconBox(context, AdaptiveIcons.heart_fill),
                subtitle: Text(S.of(context).nSongs(favouritesCount)),
                trailing: Icon(AdaptiveIcons.chevron_right),
                onTap: () => context.push('/saved/favourites_page'),
              ),

              /// DOWNLOADS
              AdaptiveListTile(
                margin: const EdgeInsets.symmetric(vertical: 4),
                title: Text(S.of(context).Downloads),
                leading: _iconBox(context, AdaptiveIcons.download),
                subtitle: Text(S.of(context).nSongs(downloadsCount)),
                trailing: Icon(AdaptiveIcons.chevron_right),
                onTap: () => context.push('/saved/downloads_page'),
              ),

              /// HISTORY
              AdaptiveListTile(
                margin: const EdgeInsets.symmetric(vertical: 4),
                title: Text(S.of(context).History),
                leading: _iconBox(context, Icons.history),
                subtitle: Text(S.of(context).nSongs(historyCount)),
                trailing: Icon(AdaptiveIcons.chevron_right),
                onTap: () => context.push('/saved/history_page'),
              ),

              /// PLAYLISTS
              Column(
                children: SplayTreeMap.from(playlists)
                    .map((key, item) {
                      if (item == null) {
                        return MapEntry(key, const SizedBox());
                      }

                      return MapEntry(
                        key,
                        AdaptiveListTile(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          title: Text(
                            item['title'],
                            maxLines: 2,
                          ),
                          leading: _playlistLeading(
                            context,
                            key,
                            item,
                          ),
                          subtitle:
                              (item['songs'] != null || item['isPredefined'])
                                  ? Text(
                                      item['isPredefined'] == true
                                          ? item['subtitle']
                                          : S.of(context).nSongs(
                                                item['songs'].length,
                                              ),
                                      maxLines: 1,
                                    )
                                  : null,
                          trailing: Icon(AdaptiveIcons.chevron_right),
                          onTap: () {
                            if (item['isPredefined'] == true) {
                              context.push(
                                '/browse',
                                extra: {
                                  'endpoint':
                                      item['endpoint'].cast<String, dynamic>(),
                                },
                              );
                            } else {
                              context.push(
                                '/saved/playlist_details',
                                extra: {
                                  'playlistkey': key,
                                },
                              );
                            }
                          },
                          onSecondaryTap: () =>
                              _showPlaylistMenu(context, key, item),
                          onLongPress: () =>
                              _showPlaylistMenu(context, key, item),
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
    );
  }

  Widget _iconBox(BuildContext context, IconData icon) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: greyColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Icon(
        icon,
        color: context.isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _playlistLeading(
    BuildContext context,
    String key,
    Map item,
  ) {
    if (item['isPredefined'] == true) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(
          item['type'] == 'ARTIST' ? 50 : 3,
        ),
        child: CachedNetworkImage(
          imageUrl: item['thumbnails']
              .first['url']
              .replaceAll('w540-h225', 'w60-h60'),
          height: 50,
          width: 50,
        ),
      );
    }

    if (item['songs'] != null && item['songs'].isNotEmpty) {
      return PlaylistThumbnail(
        playslist: item['songs'],
        size: 50,
        radius: item['type'] == 'ARTIST' ? 50 : 8,
      );
    }

    return _iconBox(context, CupertinoIcons.music_note_list);
  }

  void _showPlaylistMenu(
    BuildContext context,
    String key,
    Map item,
  ) {
    if (item['videoId'] == null && item['playlistId'] != null) {
      Modals.showPlaylistBottomModal(context, item);
    } else if (item['isPredefined'] == false) {
      Modals.showPlaylistBottomModal(
        context,
        {...item, 'playlistId': key},
      );
    }
  }
}
