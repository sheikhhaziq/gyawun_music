import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/utils/extensions.dart';
import 'package:gyawun/utils/pprint.dart';
import 'package:gyawun/utils/song_thumbnail.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../generated/l10n.dart';
import '../../services/bottom_message.dart';
import '../../services/download_manager.dart';
import '../../services/media_player.dart';
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
          AdaptiveButton(
              child: Icon(AdaptiveIcons.delete),
              onPressed: () async {
                bool shouldDelete = await Modals.showConfirmBottomModal(context,
                    message:
                        'Are you sure you want to delete all downloaded songs.',
                    isDanger: true,
                    doneText: S.of(context).Yes,
                    cancelText: S.of(context).No);

                if (shouldDelete) {
                  Modals.showCenterLoadingModal(context);
                  List songs = Hive.box('DOWNLOADS').values.toList();
                  for (var song in songs) {
                    String path = song['path'];
                    await Hive.box('DOWNLOADS').delete(song['videoId']);
                    try {
                      File(path).delete();
                    } catch (e) {
                      pprint(e);
                    }
                  }
                  Navigator.pop(context);
                }
              }),
          const SizedBox(width: 8),
          AdaptiveButton(
              child: Icon(AdaptiveIcons.download),
              onPressed: () {
                context.push('/saved/downloads/downloading');
              })
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ValueListenableBuilder(
                valueListenable: GetIt.I<DownloadManager>().downloads,
                builder: (context, allSongs, snapshot) {
                  List songs = allSongs
                      .where((song) =>
                          ['DOWNLOADED', 'DELETED'].contains(song['status']))
                      .toList();
                  songs.sort((a, b) =>
                      (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

                  return Column(
                    children: [
                      ...songs.indexed.map<Widget>((indexedSong) {
                        int index = indexedSong.$1;
                        Map song = indexedSong.$2;
                        return FutureBuilder(
                            future: File(song['path']).exists(),
                            builder: (context, snapshot) {
                              if (snapshot.data == false) {
                                GetIt.I<DownloadManager>()
                                    .updateStatus(song['videoId'], 'DELETED');
                                // return const SizedBox();
                              }
                              return SwipeActionCell(
                                backgroundColor: Colors.transparent,
                                key: ObjectKey(song['videoId']),
                                trailingActions: <SwipeAction>[
                                  if (snapshot.data == true)
                                    SwipeAction(
                                        title: S.of(context).Remove,
                                        onTap:
                                            (CompletionHandler handler) async {
                                          Modals.showConfirmBottomModal(
                                            context,
                                            message:
                                                S.of(context).Remove_Message,
                                            isDanger: true,
                                          ).then((bool confirm) {
                                            if (confirm) {
                                              GetIt.I<DownloadManager>()
                                                  .deleteSong(song['videoId'],
                                                      song['path'])
                                                  .then((message) =>
                                                      BottomMessage.showText(
                                                          context, message));
                                            }
                                          });
                                        },
                                        color: Colors.red),
                                ],
                                child: DownloadedSongTile(
                                    songs: songs, index: index),
                              );
                            });
                      })
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
