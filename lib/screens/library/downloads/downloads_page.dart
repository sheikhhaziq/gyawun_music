import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/core/widgets/expressive_app_bar.dart';
import 'package:gyawun/core/widgets/expressive_list_tile.dart';
import 'package:gyawun/services/download_manager.dart';

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
          ExpressiveAppBar(
            title: S.of(context).Downloads,
            hasLeading: true,
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
      body: ListView.separated(
        itemCount: sortedEntries.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        separatorBuilder: (context, index) => SizedBox(height: 4),
        itemBuilder: (context, index) {
          final playlist = sortedEntries[index].value;
          return ExpressiveListTile(
            title: playlist['type'] == 'SONGS'
                ? Text(S.of(context).Songs)
                : Text(playlist['title']),
            leading: _leading(context, playlist),
            subtitle: Text(S.of(context).nSongs(playlist['songs'].length)),
            trailing: const Icon(FluentIcons.chevron_right_24_filled),
            onTap: () {
              context.push(
                '/library/downloads/download_playlist',
                extra: {'playlistId': playlist['id']},
              );
            },

            onLongPress: () {
              Modals.showDownloadDetailsBottomModal(context, playlist);
            },
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
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      );
    }

    if (playlist['type'] == 'ALBUM') {
      return PlaylistThumbnail(playlist: [playlist['songs'][0]], size: 40);
    }

    return PlaylistThumbnail(playlist: playlist['songs'], size: 40);
  }
}
