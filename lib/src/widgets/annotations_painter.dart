import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:graphic_lite/src/display/annotation.dart';
import 'package:graphic_lite/src/display/arrow.dart';
import 'package:graphic_lite/src/display/enums.dart';

/// [CustomPainter] that renders [Annotation] overlays on top of a chart.
///
/// Each annotation has:
///   - A text box drawn at the **tail** position.
///   - An optional [Arrow] drawn from the tail to the **head** (the data point
///     at `(x, y)` in the annotation's coordinate system).
///
/// Coordinate conventions (matching Plotly):
///   - `xRef / yRef == 'x' / 'y'` : data coordinates.
///   - `xRef / yRef == 'paper'`    : normalised 0–1 across the plot area.
///
/// Arrow offset (`ax`, `ay`) in pixel mode (`axRef / ayRef == 'pixel'`):
///   - `ax > 0` : tail is to the **right** of the head.
///   - `ay > 0` : tail is **below** the head (canvas y increases downward).
///   - `ay = -40` places the tail 40 px **above** the head — the typical
///     pattern for labelling a data point with text above and an arrow pointing
///     down to it.
class AnnotationsPainter extends CustomPainter {
  AnnotationsPainter({
    required this.annotations,
    required this.domainX,
    required this.domainY,
  });

  final List<Annotation> annotations;
  final (num, num) domainX;
  final (num, num) domainY;

  // Must match the padding used by g.Chart (see chart.dart).
  static const double _leftPad = 40.0;
  static const double _topPad = 5.0;
  static const double _rightPad = 10.0;
  static const double _bottomPad = 40.0;

  // ── coordinate helpers ───────────────────────────────────────────────────

  Offset _toPixel(double dx, double dy, Size size, String xRef, String yRef) {
    final plotW = size.width - _leftPad - _rightPad;
    final plotH = size.height - _topPad - _bottomPad;

    final px = xRef == 'paper'
        ? _leftPad + dx * plotW
        : _leftPad + (dx - domainX.$1) / (domainX.$2 - domainX.$1) * plotW;

    // Data y-axis increases upward; canvas y increases downward — invert.
    final py = yRef == 'paper'
        ? _topPad + (1.0 - dy) * plotH
        : _topPad +
              (1.0 - (dy - domainY.$1) / (domainY.$2 - domainY.$1)) * plotH;

    return Offset(px, py);
  }

  // ── text helpers ─────────────────────────────────────────────────────────

  TextPainter _buildTextPainter(Text widget, double maxWidth) {
    final InlineSpan span;
    if (widget.textSpan != null) {
      span = widget.textSpan!;
    } else {
      span = TextSpan(
        text: widget.data ?? '',
        style:
            widget.style ??
            const TextStyle(fontSize: 12, color: Color(0xFF000000)),
      );
    }
    return TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: widget.textAlign ?? TextAlign.left,
    )..layout(maxWidth: maxWidth);
  }

  // ── main paint ───────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final maxW = size.width - _leftPad - _rightPad;

    for (final ann in annotations) {
      // Head: the annotated data point.
      final xNum = ann.x is num ? (ann.x as num).toDouble() : 0.0;
      final yNum = ann.y is num ? (ann.y as num).toDouble() : 0.0;
      final head = _toPixel(xNum, yNum, size, ann.xRef, ann.yRef);

      // Tail: where the text box is anchored.
      final Offset tail;
      if (ann.arrow != null) {
        // ax positive  → tail to the right of head  (standard canvas x)
        // ay positive  → tail below head             (canvas y increases down)
        tail = Offset(
          head.dx + ann.arrow!.ax.toDouble(),
          head.dy + ann.arrow!.ay.toDouble(),
        );
      } else {
        tail = head;
      }

      // Apply pixel shift from xShift / yShift (these shift both box and arrow).
      final shiftedTail = Offset(
        tail.dx + ann.xShift.toDouble(),
        tail.dy - ann.yShift.toDouble(), // yShift positive = upward
      );
      final shiftedHead = Offset(
        head.dx + ann.xShift.toDouble(),
        head.dy - ann.yShift.toDouble(),
      );

      // Build text painter.
      final tp = _buildTextPainter(ann.text, maxW);
      final textW = tp.width;
      final textH = tp.height;
      final pad = ann.borderPadding.toDouble();
      final boxW = textW + 2 * pad;
      final boxH = textH + 2 * pad;

      // Determine box origin based on xAnchor / yAnchor.
      // "auto" with an arrow is treated as "center" / "middle".
      final double boxLeft = switch (ann.xAnchor) {
        XAnchor.left => shiftedTail.dx,
        XAnchor.right => shiftedTail.dx - boxW,
        _ => shiftedTail.dx - boxW / 2, // center / auto
      };
      final double boxTop = switch (ann.yAnchor) {
        YAnchor.top => shiftedTail.dy,
        YAnchor.bottom => shiftedTail.dy - boxH,
        _ => shiftedTail.dy - boxH / 2, // middle / auto
      };
      final boxRect = Rect.fromLTWH(boxLeft, boxTop, boxW, boxH);

      // Draw the arrow beneath the text box.
      if (ann.arrow != null && ann.arrow!.side != ArrowSide.none) {
        _drawArrow(canvas, shiftedTail, shiftedHead, ann.arrow!, boxRect);
      }
      // Background fill.
      final bg = ann.backgroundColor;
      if (bg.a > 0) {
        canvas.drawRect(boxRect, Paint()..color = bg);
      }

      // Border.
      final bc = ann.borderColor;
      if (bc.a > 0 && ann.borderWidth > 0) {
        canvas.drawRect(
          boxRect,
          Paint()
            ..color = bc
            ..style = PaintingStyle.stroke
            ..strokeWidth = ann.borderWidth.toDouble(),
        );
      }

      // Text — supports rotation around the text-box centre.
      if (ann.textAngle != 0) {
        final cx = boxLeft + boxW / 2;
        final cy = boxTop + boxH / 2;
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(ann.textAngle * math.pi / 180);
        tp.paint(canvas, Offset(-textW / 2, -textH / 2));
        canvas.restore();
      } else {
        tp.paint(canvas, Offset(boxLeft + pad, boxTop + pad));
      }
    }
  }

  // ── arrow drawing ─────────────────────────────────────────────────────────

  /// Draws an arrow from [tail] to [head], starting at the edge of [boxRect]
  /// so the line doesn't overlap the text box.
  void _drawArrow(
    Canvas canvas,
    Offset tail,
    Offset head,
    Arrow arrow,
    Rect boxRect,
  ) {
    final color = arrow.color;
    final width = arrow.width.toDouble();
    final headSize = arrow.headSize.toDouble();
    final side = arrow.side ?? ArrowSide.end;

    final dx = head.dx - tail.dx;
    final dy = head.dy - tail.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 0.5) return;
    final ux = dx / dist;
    final uy = dy / dist;

    // Tip geometry scales with arrow width so it looks proportional.
    final tipLen = math.max(6.0, 6.0 * headSize * width);
    final tipHalf = math.max(3.0, 3.0 * headSize * width);

    // Start the line at the box edge (so it doesn't overlap the text).
    final lineStart = _intersectBoxEdge(tail, head, boxRect) ?? tail;

    // Stop the line just short of the arrowhead base so it doesn't poke through.
    final lineEnd = (side == ArrowSide.end || side == ArrowSide.both)
        ? Offset(head.dx - ux * tipLen, head.dy - uy * tipLen)
        : head;
    final lineStartAdj = (side == ArrowSide.start || side == ArrowSide.both)
        ? Offset(lineStart.dx + ux * tipLen, lineStart.dy + uy * tipLen)
        : lineStart;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(lineStartAdj, lineEnd, linePaint);

    if (side == ArrowSide.end || side == ArrowSide.both) {
      _drawTip(canvas, head, ux, uy, tipLen, tipHalf, color);
    }
    if (side == ArrowSide.start || side == ArrowSide.both) {
      _drawTip(canvas, lineStart, -ux, -uy, tipLen, tipHalf, color);
    }
  }

  /// Draws a filled triangular arrowhead at [tip] pointing in direction (ux, uy).
  void _drawTip(
    Canvas canvas,
    Offset tip,
    double ux,
    double uy,
    double tipLen,
    double tipHalf,
    Color color,
  ) {
    final base = Offset(tip.dx - ux * tipLen, tip.dy - uy * tipLen);
    final px = -uy * tipHalf;
    final py = ux * tipHalf;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + px, base.dy + py)
      ..lineTo(base.dx - px, base.dy - py)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  /// Returns the point where the line from [from] toward [to] exits [box],
  /// i.e. the intersection of the ray with the nearest box edge. Returns
  /// null if [from] is outside the box (arrow starts outside — no clipping).
  Offset? _intersectBoxEdge(Offset from, Offset to, Rect box) {
    // If the tail centre is not inside the box, no clipping is needed.
    if (!box.contains(from)) return null;

    // Check the four edges and return the closest intersection.
    final edges = [
      (box.topLeft, box.topRight), // top
      (box.bottomLeft, box.bottomRight), // bottom
      (box.topLeft, box.bottomLeft), // left
      (box.topRight, box.bottomRight), // right
    ];

    Offset? best;
    double bestDist = double.infinity;
    for (final (a, b) in edges) {
      final pt = _segmentIntersect(from, to, a, b);
      if (pt != null) {
        final d = (pt - from).distance;
        if (d < bestDist) {
          bestDist = d;
          best = pt;
        }
      }
    }
    return best;
  }

  /// Standard 2-D segment–segment intersection. Returns null if the
  /// segments do not intersect within their extents.
  Offset? _segmentIntersect(Offset p, Offset q, Offset r, Offset s) {
    final d1x = q.dx - p.dx;
    final d1y = q.dy - p.dy;
    final d2x = s.dx - r.dx;
    final d2y = s.dy - r.dy;
    final denom = d1x * d2y - d1y * d2x;
    if (denom.abs() < 1e-10) return null;
    final t = ((r.dx - p.dx) * d2y - (r.dy - p.dy) * d2x) / denom;
    final u = ((r.dx - p.dx) * d1y - (r.dy - p.dy) * d1x) / denom;
    if (t < 0 || t > 1 || u < 0 || u > 1) return null;
    return Offset(p.dx + t * d1x, p.dy + t * d1y);
  }

  @override
  bool shouldRepaint(AnnotationsPainter old) =>
      old.annotations != annotations ||
      old.domainX != domainX ||
      old.domainY != domainY;
}
