import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/core/widgets/sections/section_multi_column.dart';
import 'package:gyawun/core/widgets/sections/section_row.dart';
import 'package:gyawun/core/widgets/song_tile.dart';
import 'package:yt_music/ytmusic.dart';

import '../../generated/l10n.dart';
import '../../services/bottom_message.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../services/media_player.dart';

class SectionItem extends StatefulWidget {
  const SectionItem({required this.section, this.isMore = false, super.key});
  final Map section;
  final bool isMore;

  @override
  State<SectionItem> createState() => _SectionItemState();
}

class _SectionItemState extends State<SectionItem> {
  final ScrollController horizontalScrollController = ScrollController();
  PageController horizontalPageController = PageController();
  bool loadingMore = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    horizontalPageController.dispose();
    horizontalScrollController.dispose();
    super.dispose();
  }

  void loadMoreItems() {
    if (widget.section['continuation'] != null) {
      setState(() {
        loadingMore = true;
      });
      GetIt.I<YTMusic>()
          .getMoreItems(continuation: widget.section['continuation'])
          .then((value) {
            setState(() {
              widget.section['contents'].addAll(value['items']);
              widget.section['continuation'] = value['continuation'];
              loadingMore = false;
            });
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    horizontalPageController = PageController(
      viewportFraction: 350 / MediaQuery.of(context).size.width,
    );
    return widget.section['contents'].isEmpty
        ? const SizedBox()
        : Column(
            children: [
              if (widget.section['title'] != null)
                SectionHeader(
                  title: widget.section['title'],
                  trailing: widget.section['trailing'],
                  contents: widget.section['contents'],
                ),
              if (widget.section['viewType'] == 'COLUMN' && !widget.isMore)
                SectionMultiColumn(items: widget.section['contents'])
              else if (widget.section['viewType'] == 'SINGLE_COLUMN' ||
                  widget.isMore)
                SingleColumnList(songs: widget.section['contents'])
              else
                SectionRow(items: widget.section['contents']),
              if (loadingMore) const AdaptiveProgressRing(),
              if (widget.section['continuation'] != null && !loadingMore)
                AdaptiveButton(
                  onPressed: loadMoreItems,
                  child: const Text("Load More"),
                ),
            ],
          );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.trailing,
    required this.contents,
  });
  final String title;
  final Map? trailing;
  final List contents;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          if (trailing != null)
            TextButton.icon(
              iconAlignment: IconAlignment.end,
              label: Text(trailing!['text']),
              icon: const Icon(FluentIcons.play_24_filled),

              onPressed: () async {
                if (trailing!['playable'] == false &&
                    trailing!['endpoint'] != null) {
                  context.push(
                    '/browse',
                    extra: {'endpoint': trailing!['endpoint'], 'isMore': true},
                  );
                } else {
                  BottomMessage.showText(
                    context,
                    S.of(context).Songs_Will_Start_Playing_Soon,
                  );
                  if (trailing!['endpoint'] != null) {
                    await GetIt.I<MediaPlayer>().startPlaylistSongs(
                      trailing!['endpoint'],
                    );
                  } else {
                    await GetIt.I<MediaPlayer>().playAll(contents);
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}

class SingleColumnList extends StatelessWidget {
  const SingleColumnList({required this.songs, super.key});
  final List songs;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: songs.map((song) {
        return Padding(
          padding: const .symmetric(horizontal: 8,vertical: 4),
          child: SongTile(song: song),
        );
      }).toList(),
    );
  }
}