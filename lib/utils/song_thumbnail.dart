import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gyawun/utils/enhanced_image.dart';

class SongThumbnail extends StatefulWidget {
  final Map song;
  final double? dp;
  final double? width;
  final double? height;
  final FilterQuality filterQuality;
  final BoxFit? fit;
  final Widget Function(BuildContext, String, Object)? errorWidget;

  const SongThumbnail({
    super.key,
    required this.song,
    this.dp,
    this.height,
    this.width,
    this.filterQuality = FilterQuality.high,
    this.fit,
    this.errorWidget,
  });

  @override
  State<SongThumbnail> createState() => _SongThumbnailState();
}

class _SongThumbnailState extends State<SongThumbnail> {
  Uint8List? thumbnailBytes;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocalThumbnail();
  }

  @override
  void didUpdateWidget(covariant SongThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.song != oldWidget.song) {
      _loadLocalThumbnail();
    }
  }

  Future<void> _loadLocalThumbnail() async {
    if (widget.song['status'] == "DOWNLOADED" && widget.song['path'] != null) {
      Tag? tag = await AudioTags.read(widget.song['path']);
      if (tag != null && tag.pictures.isNotEmpty) {
        setState(() {
          thumbnailBytes = tag.pictures.first.bytes;
        });
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? SizedBox()
        : thumbnailBytes != null
            ? Image.memory(
                thumbnailBytes!,
                height: widget.height,
                width: widget.width,
                fit: widget.fit,
              )
            : CachedNetworkImage(
                imageUrl: getEnhancedImage(
                  widget.song['thumbnails'].first['url'],
                  dp: widget.dp,
                  width: widget.width,
                ),
                height: widget.height,
                width: widget.width,
                filterQuality: widget.filterQuality,
                fit: widget.fit,
                errorWidget: (context, url, error) {
                  return CachedNetworkImage(
                    imageUrl: getEnhancedImage(
                      widget.song['thumbnails'].first['url'],
                      quality: 'medium',
                    ),
                    height: widget.height,
                    width: widget.width,
                    filterQuality: widget.filterQuality,
                    fit: widget.fit,
                    errorWidget: (context, url, error) {
                      return CachedNetworkImage(
                        imageUrl: getEnhancedImage(
                          widget.song['thumbnails'].first['url'],
                          quality: 'low',
                        ),
                        height: widget.height,
                        width: widget.width,
                        filterQuality: widget.filterQuality,
                        fit: widget.fit,
                        errorWidget: widget.errorWidget,
                      );
                    },
                  );
                },
              );
  }
}
