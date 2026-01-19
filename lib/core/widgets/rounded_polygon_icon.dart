import 'package:flutter/material.dart';
import 'package:m3e_collection/m3e_collection.dart';

class RoundedPolygonIcon extends StatelessWidget {
  final RoundedPolygon polygon;
  final Color? color;
  final double size;

  const RoundedPolygonIcon({
    super.key,
    required this.polygon,
    this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).iconTheme.color ?? Colors.black;
    
    return CustomPaint(
      size: Size(size, size),
      painter: _RoundedPolygonPainter(
        polygon: polygon,
        color: iconColor,
      ),
    );
  }
}

class _RoundedPolygonPainter extends CustomPainter {
  final RoundedPolygon polygon;
  final Color color;

  _RoundedPolygonPainter({
    required this.polygon,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = polygon.toPath();
    
    // Get the bounds of the polygon
    final bounds = path.getBounds();
    
    // Scale and center the polygon to fit the icon size
    final scaleX = size.width / bounds.width;
    final scaleY = size.height / bounds.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    
    canvas.save();
    canvas.translate(
      size.width / 2 - bounds.center.dx * scale,
      size.height / 2 - bounds.center.dy * scale,
    );
    canvas.scale(scale);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RoundedPolygonPainter oldDelegate) {
    return oldDelegate.polygon != polygon || oldDelegate.color != color;
  }
}