import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/utils/extensions.dart';

import '../../generated/l10n.dart';
import '../../services/download_manager.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';

class DownloadingScreen extends StatelessWidget {
  const DownloadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        title: Text(S.of(context).Downloads),
        centerTitle: true,
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
                      .where((song) => ['DOWNLOADING'].contains(song['status']))
                      .toList();
                  return Column(
                    children: [
                      ...songs.indexed.map<Widget>((indexedSong) {
                        int index = indexedSong.$1;
                        return DownloadingSongTile(songs: songs, index: index);
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

class DownloadingSongTile extends StatelessWidget {
  const DownloadingSongTile(
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
      title: Text(song['title'] ?? "", maxLines: 1),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: CachedNetworkImage(
          imageUrl:
              thumbnails.where((el) => el['width'] >= 50).toList().first['url'],
          height: height,
          width: 50,
          fit: BoxFit.cover,
        ),
      ),
      subtitle: LinearProgressIndicator(
        value: (song['progress'] ?? 0) / 100,
        color: Theme.of(context).primaryColor,
        backgroundColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
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
}
