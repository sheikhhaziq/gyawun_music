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
        title: Text(S.of(context).Downloading),
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
          valueListenable: GetIt.I<DownloadManager>().downloads,
          builder: (context, allSongs, snapshot) {
            List downloadingSongs = allSongs
                .where((song) => ['DOWNLOADING'].contains(song['status']))
                .toList();
            List queuedSongs = GetIt.I<DownloadManager>().getDownloadQueue();
            return CustomScrollView(
              slivers: [
                if (downloadingSongs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                      child: SectionTitle(title: S.of(context).In_Progress)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          DownloadingSongTile(song: downloadingSongs[index]),
                      childCount: downloadingSongs.length,
                    ),
                  ),
                ],
                if (queuedSongs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                      child: SectionTitle(
                          title:
                              S.of(context).QueuedCount(queuedSongs.length))),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          DownloadingSongTile(song: queuedSongs[index]),
                      childCount: queuedSongs.length,
                    ),
                  ),
                ],
              ],
            );
          }),
    );
  }
}

class DownloadingSongTile extends StatelessWidget {
  const DownloadingSongTile({required this.song, super.key});
  final Map song;
  @override
  Widget build(BuildContext context) {
    List thumbnails = song['thumbnails'];
    double height =
        (song['aspectRatio'] != null ? 50 / song['aspectRatio'] : 50)
            .toDouble();
    final notifier =
        GetIt.I<DownloadManager>().getProgressNotifier(song['videoId']);
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
      subtitle: (notifier != null)
          ? ValueListenableBuilder(
              valueListenable: notifier,
              builder: (context, progress, child) => LinearProgressIndicator(
                value: progress,
                color: Theme.of(context).primaryColor,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.3),
              ),
            )
          : LinearProgressIndicator(
              value: 0.0,
              color: Theme.of(context).primaryColor,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
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

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
