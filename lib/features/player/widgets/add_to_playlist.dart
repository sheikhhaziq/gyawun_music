import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gyawun_music/core/di.dart';
import 'package:gyawun_music/core/utils/modals.dart';
import 'package:gyawun_shared/gyawun_shared.dart';
import 'package:library_manager/library_manager.dart';

class AddToPlaylist extends StatefulWidget {
  const AddToPlaylist({
    super.key,
    required this.item,
    this.iconSize = 24,
    this.padding = const EdgeInsets.all(10),
  });
  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final PlayableItem item;

  @override
  State<AddToPlaylist> createState() => _AddToPlaylistState();
}

class _AddToPlaylistState extends State<AddToPlaylist> {
  bool? isInAllPlaylists;
  late PlayableItem item;

  @override
  void initState() {
    super.initState();
    item = widget.item;
    isInAllPlaylists = sl<LibraryManager>()
        .getPlaylistsNotContainingItem(item.id, item.provider)
        .isEmpty;
  }

  @override
  didUpdateWidget(covariant AddToPlaylist oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      item = widget.item;
      isInAllPlaylists = sl<LibraryManager>()
          .getPlaylistsNotContainingItem(item.id, item.provider)
          .isEmpty;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return isInAllPlaylists == true
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: IconButton.filled(
              onPressed: () async {
                await Modals.showAddToPlaylist(context, item);
                isInAllPlaylists = sl<LibraryManager>()
                    .getPlaylistsNotContainingItem(item.id, item.provider)
                    .isEmpty;
                setState(() {});
              },
              padding: widget.padding,
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(cs.secondaryContainer),
                foregroundColor: WidgetStatePropertyAll(cs.onSecondaryContainer),
              ),
              icon: Icon(
                FluentIcons.add_24_filled,
                size: widget.iconSize,
                color: cs.onSecondaryContainer,
              ),
            ),
          );
  }
}
