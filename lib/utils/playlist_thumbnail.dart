import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gyawun/utils/song_thumbnail.dart';

class PlaylistThumbnail extends StatelessWidget {
  final List playslist;
  final double size;
  final double radius;

  const PlaylistThumbnail({
    super.key,
    required this.playslist,
    required this.size,
    this.radius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: size,
        width: size,
        child: StaggeredGrid.count(
          crossAxisCount: playslist.length > 1 ? 2 : 1,
          children: (playslist)
              .sublist(0, min(playslist.length, 4))
              .indexed
              .map((ind) {
            int index = ind.$1;
            Map song = ind.$2;
            return SongThumbnail(
              song: song,
              height: (playslist.length <= 2 ||
                      (playslist.length == 3 && index == 0))
                  ? size
                  : size / 2,
              width: size / 2,
              fit: BoxFit.cover,
            );
          }).toList(),
        ),
      ),
    );
  }
}
