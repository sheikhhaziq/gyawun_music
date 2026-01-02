import 'dart:collection';

import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun/utils/extensions.dart';
import 'package:gyawun/utils/internet_guard.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';
import '../../services/library.dart';
import '../../themes/colors.dart';
import '../../utils/adaptive_widgets/adaptive_widgets.dart';
import '../../utils/bottom_modals.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Map playlists = context.watch<LibraryService>().playlists;
    return InternetGuard(
      child: AdaptiveScaffold(
        appBar: AdaptiveAppBar(
          title: Text(S.of(context).Saved),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            AdaptiveIconButton(
              onPressed: () {
                Modals.showImportplaylistModal(context);
              },
              icon: Icon(
                AdaptiveIcons.import,
                size: 25,
              ),
            ),
            AdaptiveIconButton(
              onPressed: () {
                Modals.showCreateplaylistModal(context);
              },
              icon: Icon(
                AdaptiveIcons.add,
                size: 25,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  AdaptiveListTile(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    title: Text(S.of(context).Favourites),
                    leading: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: greyColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        AdaptiveIcons.heart_fill,
                        color: context.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: ValueListenableBuilder(
                      valueListenable: Hive.box('FAVOURITES').listenable(),
                      builder: (context, box, child) {
                        return Text(S.of(context).nSongs(box.length));
                      },
                    ),
                    trailing: Icon(AdaptiveIcons.chevron_right),
                    onTap: () => context.push('/saved/favourite_details'),
                  ),
                  AdaptiveListTile(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    title: Text(S.of(context).Downloads),
                    leading: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: greyColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        AdaptiveIcons.download,
                        color: context.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: ValueListenableBuilder(
                      valueListenable: Hive.box('DOWNLOADS').listenable(),
                      builder: (context, box, child) {
                        List values = box.values.toList();
                        List downloaded = values
                            .where(
                                (element) => element['status'] == 'DOWNLOADED')
                            .toList();
                        return Text(S.of(context).nSongs(downloaded.length));
                      },
                    ),
                    trailing: Icon(AdaptiveIcons.chevron_right),
                    onTap: () => context.push('/saved/downloads'),
                  ),
                  AdaptiveListTile(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    title: Text(S.of(context).History),
                    leading: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: greyColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        Icons.history,
                        color: context.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: ValueListenableBuilder(
                      valueListenable: Hive.box('SONG_HISTORY').listenable(),
                      builder: (context, box, child) {
                        return Text(S.of(context).nSongs(box.length));
                      },
                    ),
                    trailing: Icon(AdaptiveIcons.chevron_right),
                    onTap: () => context.push('/saved/history'),
                  ),
                  Column(
                    children: SplayTreeMap.from(playlists)
                        .map((key, item) {
                          return MapEntry(
                            key,
                            item == null
                                ? const SizedBox.shrink()
                                : AdaptiveListTile(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    onSecondaryTap: () {
                                      if (item['videoId'] == null &&
                                          item['playlistId'] != null) {
                                        Modals.showPlaylistBottomModal(
                                            context, item);
                                      } else if (item['isPredefined'] ==
                                          false) {
                                        Modals.showPlaylistBottomModal(context,
                                            {...item, 'playlistId': key});
                                      }
                                    },
                                    onLongPress: () {
                                      if (item['videoId'] == null &&
                                          item['playlistId'] != null) {
                                        Modals.showPlaylistBottomModal(
                                            context, item);
                                      } else if (item['isPredefined'] ==
                                          false) {
                                        Modals.showPlaylistBottomModal(context,
                                            {...item, 'playlistId': key});
                                      }
                                    },
                                    onTap: () {
                                      if (item['isPredefined']) {
                                        context.push(
                                          '/browse',
                                          extra: {
                                            'endpoint': item['endpoint']
                                                .cast<String, dynamic>()
                                          },
                                        );
                                      } else {
                                        context.push(
                                          '/saved/playlist_details',
                                          extra: {'playlistkey': key},
                                        );
                                      }
                                    },
                                    title: Text(
                                      item['title'],
                                      maxLines: 2,
                                    ),
                                    leading: item['isPredefined'] == true ||
                                            (item['songs'] != null &&
                                                item['songs']?.length > 0)
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                item['type'] == 'ARTIST'
                                                    ? 50
                                                    : 3),
                                            child: item['isPredefined'] == true
                                                ? CachedNetworkImage(
                                                    imageUrl: item['thumbnails']
                                                        .first['url']
                                                        .replaceAll('w540-h225',
                                                            'w60-h60'),
                                                    height: 50,
                                                    width: 50,
                                                  )
                                                : SizedBox(
                                                    height: 50,
                                                    width: 50,
                                                    child: StaggeredGrid.count(
                                                      crossAxisCount:
                                                          item['songs'].length >
                                                                  1
                                                              ? 2
                                                              : 1,
                                                      children: (item['songs']
                                                              as List)
                                                          .sublist(
                                                              0,
                                                              min(
                                                                  item['songs']
                                                                      .length,
                                                                  4))
                                                          .indexed
                                                          .map((ind) {
                                                        int index = ind.$1;
                                                        Map song = ind.$2;
                                                        return CachedNetworkImage(
                                                          imageUrl: song[
                                                                  'thumbnails']
                                                              .first['url']
                                                              .replaceAll(
                                                                  'w540-h225',
                                                                  'w60-h60'),
                                                          height: (item['songs']
                                                                          .length <=
                                                                      2 ||
                                                                  (item['songs']
                                                                              .length ==
                                                                          3 &&
                                                                      index ==
                                                                          0))
                                                              ? 50
                                                              : null,
                                                          fit: BoxFit.cover,
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ),
                                          )
                                        : Container(
                                            height: 50,
                                            width: 50,
                                            decoration: BoxDecoration(
                                              color: greyColor,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: Icon(
                                              CupertinoIcons.music_note_list,
                                              color: context.isDarkMode
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                    subtitle: (item['songs'] != null ||
                                            item['isPredefined'])
                                        ? Text(
                                            item['isPredefined'] == true
                                                ? item['subtitle']
                                                : S.of(context).nSongs(
                                                    item['songs'].length),
                                            maxLines: 1,
                                          )
                                        : null,
                                    trailing: Icon(AdaptiveIcons.chevron_right),
                                  ),
                          );
                        })
                        .values
                        .toList(),
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
