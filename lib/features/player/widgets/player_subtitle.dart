import 'package:flutter/material.dart';

class PlayerSubtitle extends StatelessWidget {
  const PlayerSubtitle({super.key, required this.subtitle, this.style});
  final TextStyle? style;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Text(
      subtitle,
      style: style ?? Theme.of(context).textTheme.bodyLarge,
      overflow: TextOverflow.ellipsis,
    );
  }
}
