
import 'package:flutter/material.dart';
import 'package:graphic_lite/graphic_lite.dart';



/// CustomPainter that draws [Shape] overlays on top or under the chart.
///
/// Coordinate systems supported via [Shape.xRef] / [Shape.yRef]:
///   - `'x'` / `'y'`  — data coordinates (default)
///   - `'paper'`      — normalized 0–1 across the plot area
class ShapesPainter extends CustomPainter {
  ShapesPainter({
    required this.shapes,
    required this.domainX,
    required this.domainY,
  });

  final List<Shape> shapes;
  final (num, num) domainX;
  final (num, num) domainY;

  // Must match the padding used by g.Chart in the build method.
  // Make this dynamic to support responsive layouts if needed.
  static const double _leftPad = 40.0;
  static const double _topPad = 5.0;
  static const double _rightPad = 10.0;
  static const double _bottomPad = 40.0;

  Offset _toPixel(double dx, double dy, Size size, String xRef, String yRef) {
    final plotW = size.width - _leftPad - _rightPad;
    final plotH = size.height - _topPad - _bottomPad;

    final px = xRef == 'paper'
        ? _leftPad + dx * plotW
        : _leftPad + (dx - domainX.$1) / (domainX.$2 - domainX.$1) * plotW;

    // y axis: data 0 = bottom of plot, increasing upward → invert.
    final py = yRef == 'paper'
        ? _topPad + (1.0 - dy) * plotH
        : _topPad +
              (1.0 - (dy - domainY.$1) / (domainY.$2 - domainY.$1)) * plotH;

    return Offset(px, py);
  }

  static Color _applyOpacity(Color c, double opacity) =>
      c.withValues(alpha: opacity);

  @override
  void paint(Canvas canvas, Size size) {
    // Clip all drawing to the plot area so shapes never overflow the axes.
    final plotRect = Rect.fromLTRB(
      _leftPad,
      _topPad,
      size.width - _rightPad,
      size.height - _bottomPad,
    );
    canvas.save();
    canvas.clipRect(plotRect);

    for (final shape in shapes) {
      if (shape.visibility != ShapeVisibility.visible) continue;

      final p0 = _toPixel(shape.x0, shape.y0, size, shape.xRef, shape.yRef);
      final p1 = _toPixel(shape.x1, shape.y1, size, shape.xRef, shape.yRef);
      final opacity = shape.fillColor.a.toDouble();

      final fillPaint = Paint()
        ..color = _applyOpacity(shape.fillColor, opacity)
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = shape.line.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = shape.line.width.toDouble();

      switch (shape.type) {
        case ShapeType.rectangle:
          final rect = Rect.fromPoints(p0, p1);
          canvas.drawRect(rect, fillPaint);
          if (shape.line.width > 0) canvas.drawRect(rect, strokePaint);
        case ShapeType.circle:
          final rect = Rect.fromPoints(p0, p1);
          canvas.drawOval(rect, fillPaint);
          if (shape.line.width > 0) canvas.drawOval(rect, strokePaint);
        case ShapeType.line:
          canvas.drawLine(p0, p1, strokePaint);
        case ShapeType.path:
          break; // not yet implemented
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(ShapesPainter old) =>
      old.shapes != shapes || old.domainX != domainX || old.domainY != domainY;
}

