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
  final void Function(ImageProvider)? onImageReady;

  const SongThumbnail({
    super.key,
    required this.song,
    this.dp,
    this.height,
    this.width,
    this.filterQuality = FilterQuality.high,
    this.fit,
    this.errorWidget,
    this.onImageReady,
  });

  @override
  State<SongThumbnail> createState() => _SongThumbnailState();
}

class _SongThumbnailState extends State<SongThumbnail> {
  MemoryImage? _localImageProvider;
  bool _isCheckingLocal = true;
  ImageProvider? _lastNotifiedProvider;

  @override
  void initState() {
    super.initState();
    _checkLocalThumbnail();
  }

  @override
  void didUpdateWidget(covariant SongThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.song != oldWidget.song) {
      _lastNotifiedProvider = null;
      _checkLocalThumbnail();
    }
  }

  Future<void> _checkLocalThumbnail() async {
    if (!_isCheckingLocal) setState(() => _isCheckingLocal = true);
    MemoryImage? foundImage;
    if (widget.song['status'] == "DOWNLOADED" && widget.song['path'] != null) {
      try {
        final Tag? tag = await AudioTags.read(widget.song['path']);
        if (tag?.pictures.isNotEmpty == true) {
          foundImage = MemoryImage(tag!.pictures.first.bytes);
        }
      } catch (e) {
        debugPrint("Errore lettura tag: $e");
        _localImageProvider = null;
        _isCheckingLocal = false;
      }
    }
    if (!mounted) return;
    setState(() {
      _localImageProvider = foundImage;
      _isCheckingLocal = false;
    });
  }

  Widget _buildDisplayImage(ImageProvider provider) {
    if (widget.onImageReady != null && provider != _lastNotifiedProvider) {
      _lastNotifiedProvider = provider;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onImageReady!(provider);
      });
    }
    return Image(
      image: provider,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      filterQuality: widget.filterQuality,
      gaplessPlayback: true,
    );
  }

  Widget _buildCachedNetworkImage(List<String> urls, int index) {
    return CachedNetworkImage(
      imageUrl: urls[index],
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
      filterQuality: widget.filterQuality,
      imageBuilder: (context, provider) => _buildDisplayImage(provider),
      errorWidget: (index + 1 < urls.length)
          ? (context, url, error) => _buildCachedNetworkImage(urls, index + 1)
          : widget.errorWidget,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLocal) return const SizedBox();
    if (_localImageProvider != null) {
      return _buildDisplayImage(_localImageProvider!);
    }
    final String baseUrl = widget.song['thumbnails'].first['url'];
    final List<String> urls = [
      getEnhancedImage(baseUrl, dp: widget.dp, width: widget.width),
      getEnhancedImage(baseUrl, quality: 'medium'),
      getEnhancedImage(baseUrl, quality: 'low'),
    ];
    return _buildCachedNetworkImage(urls, 0);
  }
}
