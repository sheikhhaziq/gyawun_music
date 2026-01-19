import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/core/widgets/library_tile.dart';
import 'package:gyawun/services/download_manager.dart';
import 'package:gyawun/themes/text_styles.dart';

import '../../../../generated/l10n.dart';
import '../../../../utils/bottom_modals.dart';
import '../../../../utils/playlist_thumbnail.dart';
import 'cubit/downloads_cubit.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DownloadsCubit()..load(),
      child: Scaffold(
        body: BlocBuilder<DownloadsCubit, DownloadsState>(
          builder: (context, state) {
            return switch (state) {
              DownloadsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              DownloadsError(:final message) => Center(child: Text(message)),
              DownloadsLoaded(:final playlists) => _DownloadsBody(
                playlists: playlists,
              ),
            };
          },
        ),
      ),
    );
  }
}

class _DownloadsBody extends StatelessWidget {
  const _DownloadsBody({required this.playlists});

  final Map playlists;

  @override
  Widget build(BuildContext context) {
    List<MapEntry> sortedEntries = playlists.entries.toList();

    sortedEntries.sort((a, b) {
      if (a.key == DownloadManager.songsPlaylistId) {
        return -1;
      } else if (b.key == DownloadManager.songsPlaylistId) {
        return 1;
      } else {
        return a.value['title'].compareTo(b.value['title']);
      }
    });

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = 120.0;
                final t = (constraints.maxHeight / (maxHeight + 30)).clamp(
                  0.0,
                  1.0,
                );
                final paddingLeft = lerpDouble(100, 16, t)!;

                return FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(left: paddingLeft, bottom: 12),
                  title: Text(
                    S.of(context).Downloads,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle(context).copyWith(fontSize: 24),
                  ),
                );
              },
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Modals.showDownloadBottomModal(context);
                },
                icon: const Icon(Icons.more_vert, size: 25),
              ),
            ],
          ),
        ];
      },
      body: ListView.builder(
        itemCount: sortedEntries.length,
        itemBuilder: (context, index) {
          final playlist = sortedEntries[index].value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: LibraryTile(
              title: playlist['type'] == 'SONGS'
                  ? Text(S.of(context).Songs)
                  : Text(playlist['title']),
              leading: _leading(context, playlist),
              subtitle: Text(S.of(context).nSongs(playlist['songs'].length)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push(
                  '/library/downloads/download_playlist',
                  extra: {'playlistId': playlist['id']},
                );
              },

              onLongPress: () {
                Modals.showDownloadDetailsBottomModal(context, playlist);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _leading(BuildContext context, Map playlist) {
    if (playlist['type'] == 'SONGS') {
      return Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.music_note,
          color: Theme.of(context).colorScheme.onPrimaryContainer
        ),
      );
    }


    if (playlist['type'] == 'ALBUM') {
      return PlaylistThumbnail(playlist: [playlist['songs'][0]], size: 40);
    }

    return PlaylistThumbnail(playlist: playlist['songs'], size: 40);
  }
}


