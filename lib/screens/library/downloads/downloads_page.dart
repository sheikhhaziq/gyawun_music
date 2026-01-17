import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/services/download_manager.dart';

import '../../../../generated/l10n.dart';
import '../../../../themes/colors.dart';
import '../../../../utils/adaptive_widgets/listtile.dart';
import '../../../../utils/bottom_modals.dart';
import '../../../../utils/extensions.dart';
import '../../../../utils/playlist_thumbnail.dart';
import 'cubit/downloads_cubit.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DownloadsCubit()..load(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).Downloads),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                Modals.showDownloadBottomModal(context);
              },
              icon: const Icon(Icons.more_vert, size: 25),
            ),
          ],
        ),
        body: BlocBuilder<DownloadsCubit, DownloadsState>(
          builder: (context, state) {
            return switch (state) {
              DownloadsLoading() =>
                const Center(child: CircularProgressIndicator()),
              DownloadsError(:final message) => Center(child: Text(message)),
              DownloadsLoaded(:final playlists) =>
                _DownloadsBody(playlists: playlists),
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

    return SingleChildScrollView(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: sortedEntries.map((entry) {
              final playlist = entry.value;

              return AdaptiveListTile(
                margin: const EdgeInsets.symmetric(vertical: 4),
                title: playlist['type'] == 'SONGS'
                    ? Text(S.of(context).Songs)
                    : Text(playlist['title']),
                leading: _leading(context, playlist),
                subtitle: Text(
                  S.of(context).nSongs(playlist['songs'].length),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push(
                    '/saved/downloads_page/download_playlist_page',
                    extra: {'playlistId': playlist['id']},
                  );
                },
                onSecondaryTap: () {
                  Modals.showDownloadDetailsBottomModal(
                    context,
                    playlist,
                  );
                },
                onLongPress: () {
                  Modals.showDownloadDetailsBottomModal(
                    context,
                    playlist,
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _leading(BuildContext context, Map playlist) {
    if (playlist['type'] == 'SONGS') {
      return Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: greyColor,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Icon(
          Icons.music_note,
          color: context.isDarkMode ? Colors.white : Colors.black,
        ),
      );
    }

    if (playlist['type'] == 'ALBUM') {
      return PlaylistThumbnail(
        playslist: [playlist['songs'][0]],
        size: 50,
      );
    }

    return PlaylistThumbnail(
      playslist: playlist['songs'],
      size: 50,
    );
  }
}
