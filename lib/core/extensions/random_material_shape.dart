import 'dart:math' as math;

import 'package:m3e_collection/m3e_collection.dart';

extension RandomMaterialShape on MaterialShapes {
  static List<RoundedPolygon> randomshapes = [
    MaterialShapes.slanted,
    MaterialShapes.pill,
    MaterialShapes.arrow,
    MaterialShapes.fan,
    MaterialShapes.clover4Leaf,
  ];
  static RoundedPolygon get random {
    final random = math.Random();
    final index = random.nextInt(randomshapes.length);
    return randomshapes[index];
  }
}
