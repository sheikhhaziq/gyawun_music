import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/utils/bottom_modals.dart';

class SectionListTile extends StatelessWidget {
  const SectionListTile({
    super.key,
    required this.item,
    this.onTap,
    this.items,
    this.isFirst = false,
    this.isLast = false,
  });
  final Map item;
  final List<Map>? items;
  final void Function()? onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final thumbnail = item['thumbnails'][0];

    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: ListTile(
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
          }
        },
        enableFeedback: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.only(
            topLeft: Radius.circular(isFirst ? 20 : 4),
            topRight: Radius.circular(isFirst ? 20 : 4),
            bottomLeft: Radius.circular(isLast ? 20 : 4),
            bottomRight: Radius.circular(isLast ? 20 : 4),
          ),
        ),
        tileColor: Theme.of(context).colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: thumbnail?['url'] == null
            ? null
            : SizedBox(
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      item['type'] == 'ARTIST'
                          ? ((50 * pixelRatio).round() / 2)
                          : 8,
                    ),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                        thumbnail!['url'],
                        maxHeight: (50 * pixelRatio).round(),
                        maxWidth: (50 * pixelRatio).round(),
                      ),
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                ),
              ),
        title: Text(
          item['title'],
          maxLines: 1,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          item['subtitle'] ??
              item['artists']?.map((e) => e['name'])?.join(',') ??
              '',
          maxLines: 1,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: item['videoId'] != null
            ? IconButton(
                onPressed: () {
                  Modals.showSongBottomModal(context, item);
                },
                icon: const Icon(Icons.more_vert_rounded),
              )
            : Icon(FluentIcons.chevron_right_24_filled),
      ),
    );
  }
}
