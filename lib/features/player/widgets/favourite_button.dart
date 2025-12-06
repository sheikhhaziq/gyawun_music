import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gyawun_music/core/di.dart';
import 'package:gyawun_shared/gyawun_shared.dart';
import 'package:library_manager/library_manager.dart';

class FavouriteButton extends StatefulWidget {
  const FavouriteButton({
    super.key,
    required this.item,
    this.iconSize = 24,
    this.padding = const EdgeInsets.all(10),
  });

  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final PlayableItem item;

  @override
  State<FavouriteButton> createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends State<FavouriteButton> {
  bool? isFavorite;
  late PlayableItem item;

  @override
  void initState() {
    super.initState();
    item = widget.item;
    isFavorite ??= sl<LibraryManager>().isFavourite(item.id, item.provider);
  }

  @override
  void didUpdateWidget(covariant FavouriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      item = widget.item;
      isFavorite = sl<LibraryManager>().isFavourite(item.id, item.provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton.filled(
        onPressed: () async {
          if (isFavorite == null) return;
          if (isFavorite!) {
            await sl<LibraryManager>().removeFavourite(item.id, item.provider);
            isFavorite = false;
          } else {
            await sl<LibraryManager>().addFavourite(item);
            isFavorite = true;
          }
          setState(() {});
        },
        padding: widget.padding,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(cs.secondaryContainer),
          foregroundColor: WidgetStatePropertyAll(cs.onSecondaryContainer),
        ),
        isSelected: isFavorite ?? false,
        icon: Icon(
          FluentIcons.heart_24_regular,
          size: widget.iconSize,
          color: cs.onSecondaryContainer,
        ),
        selectedIcon: Icon(
          FluentIcons.heart_24_filled,
          size: widget.iconSize,
          color: cs.onSecondaryContainer,
        ),
      ),
    );
  }
}
