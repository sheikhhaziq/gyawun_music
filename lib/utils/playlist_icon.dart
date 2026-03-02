import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';

abstract class PlaylistIcon {
  final String id;

  const PlaylistIcon(this.id);

  String toId() => id;
}

class MaterialPlaylistIcon extends PlaylistIcon {
  final IconData iconData;

  const MaterialPlaylistIcon(super.id, this.iconData);
}

class PolygonPlaylistIcon extends PlaylistIcon {
  final RoundedPolygon polygon;

  const PolygonPlaylistIcon(super.id, this.polygon);
}
