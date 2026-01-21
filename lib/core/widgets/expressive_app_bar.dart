import 'dart:ui';

import 'package:flutter/material.dart';

class ExpressiveAppBar extends StatelessWidget {
  const ExpressiveAppBar({
    super.key,
    this.title,
    this.child,
    this.hasLeading = false,
    this.actions,
  });
  final bool hasLeading;
  final String? title;
  final Widget? child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      actions: actions,
      flexibleSpace: hasLeading
          ? LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = 120.0;
                final t = (constraints.maxHeight / (maxHeight + 30)).clamp(
                  0.0,
                  1.0,
                );
                final paddingLeft = lerpDouble(100, 16, t)!;

                return _ExpressiveFlexSpaceBar(
                  paddingLeft: paddingLeft,
                  title: title,
                  child: child,
                );
              },
            )
          : _ExpressiveFlexSpaceBar(
              paddingLeft: 16,
              title: title,
              child: child,
            ),
    );
  }
}

class _ExpressiveFlexSpaceBar extends StatelessWidget {
  const _ExpressiveFlexSpaceBar({
    required this.paddingLeft,
    this.title,
    this.child,
  });

  final double paddingLeft;
  final String? title;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return FlexibleSpaceBar(
      titlePadding: EdgeInsets.only(left: paddingLeft, bottom: 12),
      title:
          child ??
          Text(
            title ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: .w600),
          ),
    );
  }
}
