import 'package:flutter/material.dart';
import 'package:gyawun/core/widgets/rounded_polygon_icon.dart';

import 'playlist_icon.dart';

class MaterialIconWidget extends StatelessWidget {
  final MaterialPlaylistIcon data;
  final double size;

  const MaterialIconWidget({super.key, required this.data, required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(
      data.iconData,
      size: size,
      color: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }
}

class PolygonIconWidget extends StatelessWidget {
  final PolygonPlaylistIcon data;
  final double size;

  const PolygonIconWidget({super.key, required this.data, required this.size});

  @override
  Widget build(BuildContext context) {
    return RoundedPolygonIcon(
      polygon: data.polygon,
      size: size,
      color: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }
}

class PlaylistIconWidget extends StatelessWidget {
  final PlaylistIcon data;
  final double size;

  const PlaylistIconWidget({super.key, required this.data, required this.size});

  @override
  Widget build(BuildContext context) {
    return switch (data) {
      MaterialPlaylistIcon m => MaterialIconWidget(data: m, size: size),
      PolygonPlaylistIcon p => PolygonIconWidget(data: p, size: size),
      _ => SizedBox(width: size, height: size),
    };
  }
}
