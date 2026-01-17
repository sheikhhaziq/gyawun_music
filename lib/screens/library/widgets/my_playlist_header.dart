import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun/generated/l10n.dart';
import 'package:gyawun/services/media_player.dart';
import 'package:gyawun/themes/colors.dart';
import 'package:gyawun/utils/adaptive_widgets/buttons.dart';
import 'package:gyawun/utils/extensions.dart';

class MyPlayistHeader extends StatelessWidget {
  const MyPlayistHeader({
    super.key,
    required this.playlist,
  });

  final Map playlist;

  Widget _buildImage(List songs, double maxWidth,
      {bool isRound = false, bool isDark = false}) {
    return (songs.isNotEmpty)
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 225,
              width: 225,
              child: StaggeredGrid.count(
                crossAxisCount: songs.length > 1 ? 2 : 1,
                axisDirection: AxisDirection.down,
                children:
                    songs.sublist(0, min(songs.length, 4)).indexed.map((ind) {
                  int index = ind.$1;
                  Map song = ind.$2;
                  return CachedNetworkImage(
                    imageUrl: song['thumbnails']
                        .first['url']
                        .replaceAll('w540-h225', 'w225-h225')
                        .replaceAll('w60-h60', 'w225-h225'),
                    height:
                        (songs.length <= 2 || (songs.length == 3 && index == 0))
                            ? 225
                            : 225 / 2,
                    width: 255 / 2,
                    fit: BoxFit.cover,
                  );
                }).toList(),
              ),
            ),
          )
        : Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: greyColor,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              CupertinoIcons.music_note_list,
              color: isDark ? Colors.white : Colors.black,
            ),
          );
  }

  Padding _buildContent(Map playlist, BuildContext context,
      {bool isRow = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Column(
        crossAxisAlignment:
            isRow ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisAlignment:
            isRow ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          if (playlist['songs'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(S.of(context).nSongs(playlist['songs'].length),
                  maxLines: 2),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (playlist['songs'].isNotEmpty)
                AdaptiveFilledButton(
                  onPressed: () {
                    GetIt.I<MediaPlayer>().playAll(playlist['songs']);
                  },
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(Platform.isWindows ? 8 : 35),
                  ),
                  color: context.isDarkMode ? Colors.white : Colors.black,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_arrow,
                        color: context.isDarkMode ? Colors.black : Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text("Play All", style: TextStyle(fontSize: 18))
                    ],
                  ),
                ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Card(
        child: LayoutBuilder(builder: (context, constraints) {
          return constraints.maxWidth > 600
              ? Row(
                  children: [
                    if (playlist['songs'] != null)
                      _buildImage(playlist['songs'], constraints.maxWidth,
                          isRound: playlist['type'] == 'ARTIST',
                          isDark: context.isDarkMode),
                    const SizedBox(width: 4),
                    Expanded(
                        child: _buildContent(playlist, context, isRow: true)),
                  ],
                )
              : Column(
                  children: [
                    if (playlist['songs'] != null)
                      _buildImage(playlist['songs'], constraints.maxWidth,
                          isRound: playlist['type'] == 'ARTIST',
                          isDark: context.isDarkMode),
                    SizedBox(height: playlist['thumbnails'] != null ? 4 : 0),
                    _buildContent(playlist, context),
                  ],
                );
        }),
      ),
    );
  }
}
