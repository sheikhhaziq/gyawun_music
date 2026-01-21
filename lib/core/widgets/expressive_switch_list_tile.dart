import 'package:flutter/material.dart';
import 'package:gyawun/core/widgets/expressive_list_tile.dart';

class ExpressiveSwitchListTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final bool enableFeedback;
  final VoidCallback? onLongPress;
  final bool selected;

  const ExpressiveSwitchListTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.leading,
    this.enableFeedback = true,
    this.onLongPress,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ExpressiveListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      onLongPress: onLongPress,
      enableFeedback: enableFeedback,
      selected: selected,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}
