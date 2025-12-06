import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gyawun_shared/gyawun_shared.dart';

class CarouselCard extends StatelessWidget {
  const CarouselCard({super.key, required this.item});
  final SectionItem item;

  @override
  Widget build(BuildContext context) {
    final image = item.thumbnails.first.url.contains('w60-h60')
        ? item.thumbnails.first.url.replaceAll('w60-h60', 'w300-h300')
        : item.thumbnails.last.url;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        CachedNetworkImage(
          imageUrl: image,
          fit: BoxFit.cover,
          errorWidget: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade300,
              child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
            );
          },
        ),
        // Dark gradient overlay for better text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.5),
                Colors.black.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Text Content
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  overflow: TextOverflow.ellipsis,
                  shadows: [
                    const Shadow(color: Colors.black45, offset: Offset(2, 2), blurRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
