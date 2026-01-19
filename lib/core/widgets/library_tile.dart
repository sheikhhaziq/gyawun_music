import 'package:flutter/material.dart';

class LibraryTile extends StatelessWidget {
  const LibraryTile({
    this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    super.key,
  });
  final Widget? title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final void Function()? onTap;
  final void Function()? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodyLarge!,
                        child: title!,
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).textTheme.bodySmall!.color,
                        ),
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}