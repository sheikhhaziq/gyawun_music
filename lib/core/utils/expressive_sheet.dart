import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gyawun/core/widgets/expressive_list_tile.dart';

class ExpressiveSheetOption<T> {
  final String label;
  final IconData? icon;
  final T value;
  final bool selected;

  const ExpressiveSheetOption({
    required this.label,
    required this.value,
    this.icon,
    this.selected = false,
  });
}

class ExpressiveSheet {
  /// Shows a modal bottom sheet with a list of options.
  /// Returns the value of the selected option, or null if dismissed.
  static Future<T?> showSelection<T>(
    BuildContext context, {
    required String title,
    required List<ExpressiveSheetOption<T>> options,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useRootNavigator: true,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
                  child: Text(
                    title,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                ...options.map((option) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ExpressiveListTile(
                      title: Text(option.label),
                      leading: option.icon != null ? Icon(option.icon) : null,
                      trailing: option.selected
                          ? Icon(FluentIcons.checkmark_24_filled)
                          : null,
                      onTap: () {
                        Navigator.pop(context, option.value);
                      },
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows a modal bottom sheet with a color selection grid.
  /// Returns the selected color, or null if dismissed/cancelled.
  static Future<Color?> showColorSelection(
    BuildContext context, {
    required String title,
    Color? currentColor,
    VoidCallback? onReset,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Preset M3-style colors
    final List<Color> presets = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      const Color(0xFF000000),
    ];

    Color? selectedColor = currentColor;

    return showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: false,
      showDragHandle: true,
      useRootNavigator: true,
      backgroundColor: colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 16,
                    left: 16,
                    right: 16,
                  ),
                  child: Text(
                    title,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: presets.length,
                    itemBuilder: (context, index) {
                      final color = presets[index];
                      final isSelected = selectedColor?.value == color.value;
                      return GestureDetector(
                        onTap: () {
                          setState(() => selectedColor = color);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: colorScheme.onSurface,
                                    width: 2.5,
                                  )
                                : Border.all(
                                    color: colorScheme.outline.withOpacity(0.1),
                                    width: 1,
                                  ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 20,
                                  color: color.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onReset != null)
                        TextButton(
                          onPressed: () {
                            onReset();
                            Navigator.pop(context, null);
                          },
                          child: const Text("Reset"),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, selectedColor),
                        child: const Text("Done"),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
