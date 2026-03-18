import 'package:flutter/material.dart';

class ColorIcon extends StatelessWidget {
  const ColorIcon({
    required this.icon,
    required this.boxColor,
    required this.iconColor,
    this.size,
    this.borderRadius,
    this.padding,
    super.key,
  });
  final IconData icon;
  final Color? boxColor;
  final Color? iconColor;
  final double? size;
  final double? borderRadius;
  final double? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding ?? 6),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(borderRadius ?? 8),
      ),
      child: Icon(icon, color: iconColor, size: size ?? 20),
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
      boxColor:
          color ??
          Theme.of(context).colorScheme.primaryContainer.withAlpha(150),
      iconColor: color != null
          ? Colors.white.withAlpha(255)
          : Theme.of(context).colorScheme.onPrimaryContainer,
      borderRadius: 24,
      padding: 12,
      size: 24,
    );
  }
}
