import 'package:flutter/material.dart';

class PlayerTitle extends StatelessWidget {
  const PlayerTitle({super.key, required this.title, this.style});
  final TextStyle? style;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style:
          style ??
          Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
