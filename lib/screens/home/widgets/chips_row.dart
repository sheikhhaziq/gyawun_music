import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChipsRow extends StatelessWidget {
  const ChipsRow({super.key, required this.chips});
  final List chips;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 12),
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: chips.map((chip) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilledButton.tonal(
              onPressed: () => context.go('/chip', extra: chip),
              child: Text(chip['title']),
            ),
          );
        }).toList(),
      ),
    );
  }
}
