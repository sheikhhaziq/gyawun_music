import 'package:flutter/material.dart';
import '../../../utils/extensions.dart';

class ColorIcon extends StatelessWidget {
  const ColorIcon({
    required this.icon,
    required this.color,
    this.size,
    this.borderRadius,
    this.padding,
    super.key,
  });
  final IconData icon;
  final Color? color;
  final double? size;
  final double? borderRadius;
  final double? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding ?? 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
      ),
      child: Icon(
        icon,
        color: (color != null || context.isDarkMode)
            ? Colors.white.withAlpha(color != null ? 255 : 200)
            : Colors.black.withAlpha(200),
        size: size ?? 20,
      ),
    );
  }
}

class SettingsColorIcon extends StatelessWidget {
  const SettingsColorIcon({super.key, required this.icon, this.color});
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ColorIcon(
      icon: icon,
      color:
          color ??
          Theme.of(context).colorScheme.primaryContainer.withAlpha(150),
      borderRadius: 24,
      padding: 12,
      size: 24,
    );
  }
}
