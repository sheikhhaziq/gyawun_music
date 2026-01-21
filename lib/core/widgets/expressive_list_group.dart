import 'package:flutter/material.dart';

class ExpressiveListGroupScope extends InheritedWidget {
  const ExpressiveListGroupScope({super.key, required super.child});

  static ExpressiveListGroupScope? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ExpressiveListGroupScope>();
  }

  @override
  bool updateShouldNotify(ExpressiveListGroupScope oldWidget) => false;
}

class ExpressiveListGroup extends StatelessWidget {
  final List<Widget> children;
  final String? title;
  final Widget? header;

  const ExpressiveListGroup({
    super.key,
    required this.children,
    this.title,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = colorScheme.surfaceContainerHigh;
    final borderRadius = BorderRadius.circular(24);

    Widget? headerWidget = header;

    if (headerWidget == null && title != null) {
      headerWidget = Padding(
        padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
        child: Text(
          title!,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (headerWidget != null) headerWidget,

        ExpressiveListGroupScope(
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor.withValues(alpha: 0.5),
              borderRadius: borderRadius,
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(children: _buildChildrenWithDividers(context)),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildChildrenWithDividers(BuildContext context) {
    final List<Widget> items = [];
    final colorScheme = Theme.of(context).colorScheme;

    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);

      // Add Divider if not the last item
      if (i < children.length - 1) {
        items.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 76,
            endIndent: 16,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        );
      }
    }
    return items;
  }
}
