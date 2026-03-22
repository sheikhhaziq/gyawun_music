import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/utils/bottom_modals.dart';

class SectionRowTile extends StatelessWidget {
  const SectionRowTile({super.key, required this.item});

  final Map item;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final imageHeight = 150;
    final isHorizontal =
        item['aspectRatio'] != null && item['aspectRatio'] != 1;
    final imageWidth = (isHorizontal ? imageHeight * (16 / 9) : imageHeight)
        .toInt();
    final thumbnail = (item['thumbnails'] as List).length > 2
        ? item['thumbnails'][1]['url']
        : item['thumbnails'][0]['url'];
    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        enableFeedback: true,
        onTap: () async {
          if (item['endpoint'] != null && item['videoId'] == null) {
            context.push('/browse', extra: {'endpoint': item['endpoint']});
          } else {
            await GetIt.I<MediaPlayer>().playSong(Map.from(item));
          }
        },
        onLongPress: () {
          if (item['videoId'] != null) {
            Modals.showSongBottomModal(context, item);
          } else if (item['playlistId'] != null) {
            Modals.showPlaylistBottomModal(context, item);
          }
        },
        onSecondaryTap: () {
          if (item['videoId'] != null) {
            Modals.showSongBottomModal(context, item);
          } else if (item['playlistId'] != null) {
            Modals.showPlaylistBottomModal(context, item);
          }
        },
        child: RepaintBoundary(
          child: SizedBox(
            height: 216,
            width: imageWidth.toDouble() + 16,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Ink(
                    height: imageHeight.toDouble(),
                    width: imageWidth.toDouble(),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        (item['type'] == 'ARTIST')
                            ? (imageWidth * pixelRatio)
                            : 8,
                      ),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(
                          thumbnail,
                          maxHeight: (imageHeight * pixelRatio).round(),
                          maxWidth: (imageWidth * pixelRatio).round(),
                        ),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  Text(
                    item['title'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item['subtitle'] != null && item['subtitle']!.isNotEmpty)
                    Text(
                      item['subtitle']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
