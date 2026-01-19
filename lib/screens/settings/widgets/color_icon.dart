import 'package:flutter/material.dart';
import '../../../utils/extensions.dart';

class ColorIcon extends StatelessWidget {
  const ColorIcon({
    required this.icon,
    required this.color,
    this.size,
    super.key,
  });
  final IconData icon;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(6),
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Icon(
          icon,
          color: (color != null || context.isDarkMode)
              ? Colors.white.withAlpha(color != null ? 255 : 200)
              : Colors.black.withAlpha(200),
          size:size?? 20,
        ));
  }
}
