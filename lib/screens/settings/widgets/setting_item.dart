import 'package:flutter/material.dart';

class GroupTitle extends StatelessWidget {
  const GroupTitle({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class SettingEmptyTile extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final Widget? leading;
  final Widget? child;
  const SettingEmptyTile(
      {super.key,
      this.isFirst = false,
      this.isLast = false,
      this.leading,
      this.child});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirst ? 20 : 4),
          topRight: Radius.circular(isFirst ? 20 : 4),
          bottomLeft: Radius.circular(isLast ? 20 : 4),
          bottomRight: Radius.circular(isLast ? 20 : 4),
        ),
      ),
      tileColor: Theme.of(context).colorScheme.surfaceContainer,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: leading == null
          ? null
          : Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withAlpha(150),
                borderRadius: BorderRadius.circular(12),
              ),
              child: leading,
            ),
      title: child,
    );
  }
}

class SettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int subtitleLines;
  final Widget leading;
  final Widget? trailing;
  final void Function()? onTap;
  final bool isFirst;
  final bool isLast;
  const SettingTile({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleLines = 1,
    required this.leading,
    this.trailing,
    this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? 20 : 4),
            topRight: Radius.circular(isFirst ? 20 : 4),
            bottomLeft: Radius.circular(isLast ? 20 : 4),
            bottomRight: Radius.circular(isLast ? 20 : 4),
          ),
        ),
        tileColor: Theme.of(context).colorScheme.surfaceContainer,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
        ),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withAlpha(150),
            borderRadius: BorderRadius.circular(12),
          ),
          child: leading,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: Theme.of(context).textTheme.labelLarge,
                maxLines: subtitleLines,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: trailing,
      ),
    );
  }
}

class SettingSwitchTile extends StatelessWidget {
  final bool value;
  final String title;
  final Widget leading;
  final String? subtitle;

  final ValueChanged<bool>? onChanged;
  final bool isFirst;
  final bool isLast;
  const SettingSwitchTile({
    super.key,
    required this.value,
    required this.title,
    required this.leading,
    this.onChanged,
    this.isFirst = false,
    this.isLast = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isFirst ? 20 : 4),
            topRight: Radius.circular(isFirst ? 20 : 4),
            bottomLeft: Radius.circular(isLast ? 20 : 4),
            bottomRight: Radius.circular(isLast ? 20 : 4),
          ),
        ),
        tileColor: Theme.of(context).colorScheme.surfaceContainer,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!, style: Theme.of(context).textTheme.labelLarge)
            : null,
        secondary: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withAlpha(150),
            borderRadius: BorderRadius.circular(12),
          ),
          child: leading,
        ),
      ),
    );
  }
}
