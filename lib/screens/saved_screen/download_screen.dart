import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/themes/colors.dart';
import 'package:gyawun/utils/extensions.dart';
import 'package:gyawun/utils/pprint.dart';
import 'package:gyawun/utils/song_thumbnail.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../generated/l10n.dart';
import '../../services/download_manager.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../utils/bottom_modals.dart';

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: Text(S.of(context).Downloads),
        centerTitle: true,
        actions: [
          AdaptiveIconButton(
            onPressed: () {
              Modals.showDownloadBottomModal(context);
            },
            icon: Icon(
              AdaptiveIcons.more_vertical,
              size: 25,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ValueListenableBuilder(
                valueListenable: GetIt.I<DownloadManager>().downloadsByPlaylist,
                builder: (context, Map allPlaylists, snapshot) {
                  List<MapEntry> sortedEntries = allPlaylists.entries.toList();
                  sortedEntries.sort((a, b) {
                    if (a.key == DownloadManager.songsPlaylistId) {
                      return -1;
                    } else if (b.key == DownloadManager.songsPlaylistId) {
                      return 1;
                    } else {
                      return a.value['title'].compareTo(b.value['title']);
                    }
                  });
                  return Column(
                    children: [
                      ...sortedEntries.map<Widget>((entry) {
                        final playlist = entry.value;
                        return AdaptiveListTile(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          title: playlist['type'] == 'SONGS'
                              ? Text(S.of(context).Songs)
                              : Text(playlist['title']),
                          leading: playlist['type'] == "SONGS"
                              ? Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    color: greyColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Icon(
                                    Icons.music_note,
                                    color: context.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                )
                              : playlist['type'] == "ALBUM"
                                  ? PlaylistThumbnail(
                                      playslist: [playlist['songs'][0]],
                                      size: 50,
                                    )
                                  : PlaylistThumbnail(
                                      playslist: playlist['songs'],
                                      size: 50,
                                    ),
                          subtitle: Text(
                              S.of(context).nSongs(playlist['songs'].length)),
                          trailing: Icon(AdaptiveIcons.chevron_right),
                          onTap: () {
                            context.push(
                              '/saved/downloads/download_details',
                              extra: {
                                'playlistId': playlist['id'],
                              },
                            );
                          },
                          onSecondaryTap: () {
                            Modals.showDownloadDetailsBottomModal(
                                context, playlist);
                          },
                          onLongPress: () {
                            Modals.showDownloadDetailsBottomModal(
                                context, playlist);
                          },
                        );
                      }),
                    ],
                  );
                }),
          ),
        ),
      ),
    );
  }
}

class DownloadedSongTile extends StatelessWidget {
  const DownloadedSongTile(
      {required this.songs, required this.index, this.playlistId, super.key});
  final String? playlistId;
  final List songs;
  final int index;
  @override
  Widget build(BuildContext context) {
    Map song = songs[index];
    List thumbnails = song['thumbnails'];
    double height =
        (song['aspectRatio'] != null ? 50 / song['aspectRatio'] : 50)
            .toDouble();
    return AdaptiveListTile(
      onTap: () async {
        if (song['status'] == 'DOWNLOADING') return;
        await GetIt.I<MediaPlayer>().playAll(List.from(songs), index: index);
      },
      onSecondaryTap: () {
        if (song['videoId'] != null && song['status'] != 'DOWNLOADING') {
          Modals.showSongBottomModal(context, song);
        }
      },
      onLongPress: () {
        if (song['videoId'] != null && song['status'] != 'DOWNLOADING') {
          Modals.showSongBottomModal(context, song);
        }
      },
      title: Text(song['title'] ?? "", maxLines: 1),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SongThumbnail(
          song: song,
          height: height,
          width: 50,
          fit: BoxFit.cover,
        ),
      ),
      subtitle: Text(
        song['status'] == 'DELETED'
            ? 'File not found'
            : song['status'] == 'DOWNLOADING'
                ? 'Downloading'
                : _buildSubtitle(song),
        maxLines: 1,
        style: TextStyle(
          color: song['status'] == 'DELETED'
              ? Colors.red
              : Colors.grey.withAlpha(250),
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: song['status'] == 'DELETED'
          ? IconButton(
              onPressed: () async {
                await GetIt.I<DownloadManager>().downloadSong(song);
              },
              icon: const Icon(Icons.refresh))
          : null,
      description: song['type'] == 'EPISODE' && song['description'] != null
          ? ExpandableText(
              song['description'].split('\n')?[0] ?? '',
              expandText: S.of(context).Show_More,
              collapseText: S.of(context).Show_Less,
              maxLines: 3,
              style: TextStyle(color: context.subtitleColor),
            )
          : null,
    );
  }

  String _buildSubtitle(Map item) {
    List sub = [];
    if (sub.isEmpty && item['artists'] != null) {
      for (Map artist in item['artists']) {
        sub.add(artist['name']);
      }
    }
    if (sub.isEmpty && item['album'] != null) {
      sub.add(item['album']['name']);
    }
    String s = sub.join(' · ');
    return item['subtitle'] ?? s;
  }
}
