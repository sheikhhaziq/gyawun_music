import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/core/widgets/library_tile.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/utils/bottom_modals.dart';

import '../../utils/song_thumbnail.dart';

class SongTile extends StatelessWidget {
  const SongTile({
    required this.song,
    this.playlistId,
    this.onTap,
    this.onLongPress,
    this.icon,
    this.onIconPress,
    this.isFirst = true,
    this.isLast = true,
    super.key,
  });
  final Map song;
  final String? playlistId;
  final Function? onTap;
  final Function? onLongPress;
  final IconData? icon;
  final Function? onIconPress;
  final bool isFirst;
  final bool isLast;

  void _onTap(BuildContext context, Map song) async {
    if (song['endpoint'] != null && song['videoId'] == null) {
      context.push('/browse', extra: {'endpoint': song['endpoint']});
    } else {
      await GetIt.I<MediaPlayer>().playSong(Map.from(song));
    }
  }

  void _onLongPress(BuildContext context, Map song) {
    if (song['videoId'] != null) {
      Modals.showSongBottomModal(context, song);
    }
  }

  void _onIconPress(BuildContext context, Map song) {
    if (song['videoId'] != null) {
      Modals.showSongBottomModal(context, song);
    }
  }

  @override
  Widget build(BuildContext context) {
    double height =
        (song['aspectRatio'] != null ? 50 / song['aspectRatio'] : 50)
            .toDouble();
    return LibraryTile(
      onTap: () => (onTap ?? _onTap)(context, song),
      onLongPress: () => (onLongPress ?? _onLongPress)(context, song),
      title: Text(
        song['title'] ?? "",
        maxLines: 1,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SongThumbnail(
          song: song,
          height: height,
          width: 50,
          fit: BoxFit.cover,
        ),
      ),
      subtitle: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (song['explicit'] == true)
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(
                Icons.explicit,
                size: 18,
                color: Colors.grey.withValues(alpha: 0.9),
              ),
            ),
          Expanded(
            child: Text(
              song['subtitle'] ??
                  song['artists']?.map((e) => e['name'])?.join(',') ??
                  '',
              maxLines: 1,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: song['videoId'] == null
          ? null
          : IconButton.filledTonal(
              onPressed: () => (onIconPress ?? _onIconPress)(context, song),
              icon: Icon(icon ?? FluentIcons.more_vertical_24_filled),
            ),
      isFirst: isFirst,
      isLast: isLast,
    );
  }
}
