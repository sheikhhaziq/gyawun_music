import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gyawun_shared/gyawun_shared.dart';

class PlayerThumbnail extends StatefulWidget {
  const PlayerThumbnail({
    super.key,
    required this.thumbnails,
    this.width = 64,
    this.borderRadius = 8,
  });

  final double width;
  final double borderRadius;
  final List<Thumbnail> thumbnails;

  @override
  State<PlayerThumbnail> createState() => _PlayerThumbnailState();
}

class _PlayerThumbnailState extends State<PlayerThumbnail> {
  String? url;

  @override
  void initState() {
    super.initState();
    if (widget.thumbnails.isEmpty) {
      url = null;
      return;
    }
    url = widget.thumbnails.first.url.contains('w60-h60')
        ? widget.thumbnails.first.url.replaceAll('w60-h60', 'w500-h500')
        : widget.thumbnails.last.url;
  }

  @override
  void didUpdateWidget(covariant PlayerThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thumbnails == widget.thumbnails) {
      return;
    }
    if (widget.thumbnails.isEmpty) {
      url = null;
      return;
    }
    url = widget.thumbnails.first.url.contains('w60-h60')
        ? widget.thumbnails.first.url.replaceAll('w60-h60', 'w500-h500')
        : widget.thumbnails.last.url;
  }

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return SizedBox(
        width: widget.width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            width: widget.width,
            height: widget.width,
            child: Icon(
              FluentIcons.music_note_2_20_regular,
              size: widget.width * 0.6,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 550),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: ClipRRect(
          key: ValueKey(url),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: CachedNetworkImage(
            imageUrl: url!,
            width: widget.width,
            fit: BoxFit.fitWidth, // Changed from cover to fitWidth
            fadeInDuration: const Duration(milliseconds: 300),
          ),
        ),
      ),
    );
  }
}
