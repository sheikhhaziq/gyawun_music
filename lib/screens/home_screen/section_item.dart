import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/ytmusic/ytmusic.dart';

import '../../generated/l10n.dart';
import '../../services/bottom_message.dart';
import '../../themes/text_styles.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../utils/enhanced_image.dart';
import '../../utils/extensions.dart';
import '../../services/media_player.dart';
import '../../utils/bottom_modals.dart';

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
        viewportFraction: 350 / MediaQuery.of(context).size.width);
    return widget.section['contents'].isEmpty
        ? const SizedBox()
        : Column(
            children: [
              if (widget.section['title'] != null)
                AdaptiveListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  title: widget.section['strapline'] == null
                      ? Text(widget.section['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20))
                      : Text(
                          widget.section['strapline'],
                          style: TextStyle(
                              color: Colors.grey.withAlpha(200), fontSize: 14),
                        ),
                  subtitle: widget.section['strapline'] != null
                      ? Text(widget.section['title'] ?? '',
                          style:
                              mediumTextStyle(context).copyWith(fontSize: 20))
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.section['trailing'] != null)
                        AdaptiveOutlinedButton(
                          onPressed: () async {
                            if (widget.section['trailing']['playable'] ==
                                    false &&
                                widget.section['trailing']['endpoint'] !=
                                    null) {
                              context.push(
                                '/browse',
                                extra: {
                                  'endpoint': widget.section['trailing']
                                      ['endpoint'],
                                  'isMore': true,
                                },
                              );
                            } else {
                              BottomMessage.showText(context,
                                  S.of(context).Songs_Will_Start_Playing_Soon);
                              if (widget.section['trailing']['endpoint'] !=
                                  null) {
                                await GetIt.I<MediaPlayer>().startPlaylistSongs(
                                    widget.section['trailing']['endpoint']);
                              } else {
                                await GetIt.I<MediaPlayer>()
                                    .playAll(widget.section['contents']);
                              }
                            }
                          },
                          child: Text(widget.section['trailing']['text']),
                        ),
                      if (Platform.isWindows &&
                          widget.section['viewType'] != 'SINGLE_COLUMN')
                        AdaptiveIconButton(
                          icon: Icon(AdaptiveIcons.chevron_left),
                          onPressed: () {
                            if (widget.section['viewType'] == 'COLUMN' &&
                                !widget.isMore) {
                              horizontalPageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut);
                            } else {
                              horizontalScrollController.animateTo(
                                horizontalScrollController.offset -
                                    horizontalScrollController
                                        .position.extentInside,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                        ),
                      if (Platform.isWindows &&
                          widget.section['viewType'] != 'SINGLE_COLUMN')
                        AdaptiveIconButton(
                          icon: Icon(AdaptiveIcons.chevron_right),
                          onPressed: () {
                            if (widget.section['viewType'] == 'COLUMN' &&
                                !widget.isMore) {
                              horizontalPageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut);
                            } else {
                              horizontalScrollController.animateTo(
                                horizontalScrollController.offset +
                                    horizontalScrollController
                                        .position.extentInside,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                        )
                    ],
                  ),
                  leading: widget.section['thumbnails'] != null &&
                          widget.section['thumbnails']?.isNotEmpty
                      ? CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(
                            widget.section['thumbnails'].first['url'],
                          ),
                        )
                      : null,
                ),
              if (widget.section['viewType'] == 'COLUMN' && !widget.isMore)
                SongList(
                  songs: widget.section['contents'],
                  controller: horizontalPageController,
                )
              else if (widget.section['viewType'] == 'SINGLE_COLUMN' ||
                  widget.isMore)
                SingleColumnList(songs: widget.section['contents'])
              else
                ItemList(
                  items: widget.section['contents'],
                  controller: horizontalScrollController,
                ),
              if (loadingMore) const AdaptiveProgressRing(),
              if (widget.section['continuation'] != null && !loadingMore)
                AdaptiveButton(
                    onPressed: loadMoreItems, child: const Text("Load More"))
            ],
          );
  }
}

// ignore: must_be_immutable
class SongList extends StatefulWidget {
  SongList({required this.songs, required this.controller, super.key});
  final List songs;
  PageController controller;

  @override
  State<SongList> createState() => _SongListState();
}

class _SongListState extends State<SongList> {
  late int num;
  late int pages;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    num = widget.songs.length <= 5 ? widget.songs.length : 4;
    pages = widget.songs.length ~/ num;
    pages = (pages * num) < widget.songs.length ? pages + 1 : pages;
    return ExpandablePageView.builder(
      controller: widget.controller,
      padEnds: false,
      itemCount: pages,
      itemBuilder: (context, index) {
        int start = index * num;
        int end = start + num;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: widget.songs
                .sublist(start, min(end, widget.songs.length))
                .map((pageSongs) {
              return SongTile(song: pageSongs);
            }).toList(),
          ),
        );
      },
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
        return SongTile(song: song);
      }).toList(),
    );
  }
}

class SongTile extends StatelessWidget {
  const SongTile({required this.song, this.playlistId, super.key});
  final String? playlistId;
  final Map song;
  @override
  Widget build(BuildContext context) {
    List thumbnails = song['thumbnails'];
    double height =
        (song['aspectRatio'] != null ? 50 / song['aspectRatio'] : 50)
            .toDouble();
    return AdaptiveListTile(
        // borderRadius: BorderRadius.circular(5),
        // focusColor: greyColor,
        onTap: () async {
          if (song['endpoint'] != null && song['videoId'] == null) {
            context.push(
              '/browse',
              extra: {
                'endpoint': song['endpoint'],
              },
            );
          } else {
            await GetIt.I<MediaPlayer>().playSong(Map.from(song));

            // final s = GetIt.I<HttpServer>();
            // await get(Uri.parse(
            //     'http://${s.address.host}:${s.port}/stream?videoId=${song['videoId']}'));
          }
        },
        onSecondaryTap: () {
          if (song['videoId'] != null) {
            Modals.showSongBottomModal(context, song);
          }
        },
        onLongPress: () {
          if (song['videoId'] != null) {
            Modals.showSongBottomModal(context, song);
          }
        },
        title: Text(song['title'] ?? "", maxLines: 1),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: CachedNetworkImage(
            imageUrl: thumbnails
                .where((el) => el['width'] >= 50)
                .toList()
                .first['url'],
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
                  color: Colors.grey.withOpacity(0.9),
                ),
              ),
            Expanded(
              child: Text(
                _buildSubtitle(song),
                maxLines: 1,
                style: TextStyle(color: Colors.grey.withOpacity(0.9)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: song['endpoint'] != null && song['videoId'] == null
            ? Icon(AdaptiveIcons.chevron_right)
            : null,
        description: (song['type'] == 'EPISODE' && song['description'] != null)
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    ExpandableText(
                      song['description'].split('\n')?[0] ?? '',
                      expandText: S.of(context).Show_More,
                      collapseText: S.of(context).Show_Less,
                      maxLines: 3,
                      style: TextStyle(color: context.subtitleColor),
                    ),
                  ],
                ),
              )
            : null);
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

class ItemList extends StatefulWidget {
  const ItemList({required this.items, this.controller, super.key});

  final List items;
  final ScrollController? controller;

  @override
  State<ItemList> createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double height = constraints.maxWidth > 600 ? 200 : 150;

      return SizedBox(
        height: height + (Platform.isWindows ? 102 : 78),
        child: ListView.separated(
          controller: widget.controller,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            double width = height * (widget.items[index]?['aspectRatio'] ?? 1);
            String? subtitle = _buildSubtitle(widget.items[index]);
            return Adaptivecard(
              elevation: 0,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: Platform.isAndroid ? Colors.transparent : null,
              padding: EdgeInsets.zero,
              child: AdaptiveInkWell(
                padding: EdgeInsets.all(Platform.isWindows ? 12 : 0),
                onTap: () async {
                  if (widget.items[index]['endpoint'] != null &&
                      widget.items[index]['videoId'] == null) {
                    context.push(
                      '/browse',
                      extra: {
                        'endpoint': widget.items[index]['endpoint'],
                      },
                    );
                  } else {
                    await GetIt.I<MediaPlayer>()
                        .playSong(Map.from(widget.items[index]));
                  }
                },
                onSecondaryTap: () {
                  if (widget.items[index]['videoId'] != null) {
                    Modals.showSongBottomModal(context, widget.items[index]);
                  } else if (widget.items[index]['playlistId'] != null) {
                    Modals.showPlaylistBottomModal(
                        context, widget.items[index]);
                  }
                },
                onLongPress: () {
                  if (widget.items[index]['videoId'] != null) {
                    Modals.showSongBottomModal(context, widget.items[index]);
                  } else if (widget.items[index]['playlistId'] != null) {
                    Modals.showPlaylistBottomModal(
                        context, widget.items[index]);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: [
                    Ink(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: widget.items[index]['type'] == 'ARTIST'
                            ? BorderRadius.circular(height / 2)
                            : BorderRadius.circular(8),
                        image: DecorationImage(
                          fit: BoxFit.cover,
                          image: CachedNetworkImageProvider(
                            getEnhancedImage(
                                widget.items[index]['thumbnails'].first['url'],
                                dp: MediaQuery.of(context).devicePixelRatio,
                                width: width),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SizedBox(
                        width: width,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AdaptiveListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 4),
                              title: Text(
                                widget.items[index]['title']
                                    .toString()
                                    .breakWord,
                                maxLines: 2,
                                style: const TextStyle(height: 1.3),
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                              ),
                              subtitle: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (widget.items[index]['explicit'] == true)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: Icon(
                                        Icons.explicit,
                                        size: 14,
                                        color: Colors.grey.withOpacity(0.9),
                                      ),
                                    ),
                                  if (subtitle != null)
                                    Expanded(
                                      child: Text(subtitle,
                                          maxLines: 1,
                                          style: TextStyle(
                                              color:
                                                  Colors.grey.withOpacity(0.9),
                                              fontSize: 13,
                                              height: 1.2),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemCount: widget.items.length,
        ),
      );
    });
  }

  String? _buildSubtitle(Map item) {
    List sub = [];
    if (item['subtitle'] != null) {
      sub.addAll(item['subtitle'].split('•'));
    } else if (item['description'] != null) {
      sub.addAll(item['description'].split(','));
    } else if (item['year'] != null) {
      sub.add(item['year']);
    }
    String s = sub.join(' • ').trim();
    return s.isEmpty ? null : s;
  }
}
