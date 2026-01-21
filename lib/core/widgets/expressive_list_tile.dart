import 'package:flutter/material.dart';
import 'package:gyawun/core/widgets/expressive_list_group.dart';

class ExpressiveListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool enableFeedback;
  final BorderRadiusGeometry? borderRadius;
  final Color? fillColor;

  const ExpressiveListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.enableFeedback = true,
    this.borderRadius,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Check if we are inside an ExpressiveListGroup
    final isInGroup = ExpressiveListGroupScope.of(context) != null;

    // Determine default values based on context (Standalone vs Grouped)
    final effectiveBorderRadius =
        borderRadius ??
        (isInGroup ? BorderRadius.zero : BorderRadius.circular(24));

    final effectiveFillColor =
        fillColor ??
        (isInGroup ? Colors.transparent : colorScheme.surfaceContainerHigh);

    // Colors
    final selectedColor = colorScheme.secondaryContainer;
    final baseColor = selected ? selectedColor : effectiveFillColor;

    // Overlay colors for InkWell (M3 specs)
    final hoverColor = colorScheme.onSurface.withValues(alpha: 0.08);
    final highlightColor = colorScheme.onSurface.withValues(alpha: 0.12);
    final splashColor = colorScheme.onSurface.withValues(alpha: 0.12);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: effectiveBorderRadius,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: effectiveBorderRadius.resolve(
            Directionality.of(context),
          ),
          hoverColor: hoverColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
          enableFeedback: enableFeedback,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Leading
                if (leading != null) ...[
                  IconTheme(
                    data: IconThemeData(
                      color: selected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    child: leading!,
                  ),
                  const SizedBox(width: 16),
                ],

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DefaultTextStyle(
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: selected
                              ? colorScheme.onSecondaryContainer
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        child: title,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        DefaultTextStyle(
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: selected
                                ? colorScheme.onSecondaryContainer.withValues(
                                    alpha: 0.8,
                                  )
                                : colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          child: subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),

                // Trailing
                if (trailing != null) ...[
                  const SizedBox(width: 16),
                  IconTheme(
                    data: IconThemeData(
                      color: colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    child: trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
