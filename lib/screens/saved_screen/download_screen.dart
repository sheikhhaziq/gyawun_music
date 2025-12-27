import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/themes/colors.dart';
import 'package:gyawun/utils/extensions.dart';
import 'package:gyawun/utils/playlist_thumbnail.dart';
import 'package:gyawun/utils/pprint.dart';
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
                    await Hive.box('DOWNLOADS').delete(song['videoId']);
                    if (song.containsKey('path')) {
                      String path = song['path'];
                      try {
                        File(path).delete();
                      } catch (e) {
                        pprint(e);
                      }
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
                valueListenable: GetIt.I<DownloadManager>().downloaded,
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
                          title: Text(playlist['title']),
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
