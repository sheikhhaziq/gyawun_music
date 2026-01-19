import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gyawun/utils/song_thumbnail.dart';

class PlaylistThumbnail extends StatefulWidget {
  final List playlist;
  final double size;
  final double radius;

  const PlaylistThumbnail({
    super.key,
    required this.playlist,
    required this.size,
    this.radius = 0,
  });

  @override
  State<PlaylistThumbnail> createState() => _PlaylistThumbnailState();
}

class _PlaylistThumbnailState extends State<PlaylistThumbnail> {
  List _itemsToDisplay = [];

  @override
  void initState() {
    super.initState();
    _calculateItems(forceUpdate: true);
  }

  @override
  void didUpdateWidget(covariant PlaylistThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    _calculateItems();
  }

  void _calculateItems({bool forceUpdate = false}) {
    final int count = min(widget.playlist.length, 4);
    final List sublist = widget.playlist.sublist(0, count);
    final List<String> currentIds =
        sublist.map((e) => e['videoId'].toString()).toList();
    final List<String> cachedIds =
        _itemsToDisplay.map((e) => e['videoId'].toString()).toList();
    if (!forceUpdate && listEquals(cachedIds, currentIds)) {
      return;
    }
    if (forceUpdate) {
      _itemsToDisplay = sublist;
    } else {
      setState(() {
        _itemsToDisplay = sublist;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        height: widget.size,
        width: widget.size,
        child: ClipRRect(
          borderRadius: .circular(8),
          child: StaggeredGrid.count(
            crossAxisCount: _itemsToDisplay.length > 1 ? 2 : 1,
            children: _itemsToDisplay.indexed.map((ind) {
              int index = ind.$1;
              Map song = ind.$2;
              return SongThumbnail(
                key: ValueKey(song['videoId']),
                song: song,
                height: (_itemsToDisplay.length <= 2 ||
                        (_itemsToDisplay.length == 3 && index == 0))
                    ? widget.size
                    : widget.size / 2,
                width: _itemsToDisplay.length > 1 ? widget.size / 2 : widget.size,
                fit: BoxFit.cover,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
