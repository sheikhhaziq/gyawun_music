import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/generated/l10n.dart';
import 'package:gyawun/services/download_manager.dart';
import 'package:gyawun/utils/adaptive_widgets/listtile.dart';
import 'package:gyawun/utils/extensions.dart';

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
