import 'dart:ui';

import 'package:graphic_lite/src/display/line.dart';

enum ShapeType { line, rectangle, circle, path }

enum ShapeVisibility { visible, hidden, legendOnly }

class Shape {
  Shape({
    required this.type,
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
    this.xRef = 'x',
    this.yRef = 'y',
    this.visibility = ShapeVisibility.visible,
    this.fillColor = const Color(0x00000000),
    Line? line,
  }) : line = line ?? Line();

  final ShapeType type;
  final double x0;
  final double y0;
  final double x1;
  final double y1;
  final ShapeVisibility visibility;
  final String xRef;
  final String yRef;

  final Color fillColor;

  final Line line;

  static Shape fromJson(Map<String, dynamic> x) {
    return Shape(
      type: ShapeType.values.firstWhere(
        (e) => e.toString() == 'ShapeType.${x['type']}',
      ),
      x0: (x['x0'] as num).toDouble(),
      y0: (x['y0'] as num).toDouble(),
      x1: (x['x1'] as num).toDouble(),
      y1: (x['y1'] as num).toDouble(),
      xRef: x['xref'] ?? 'x',
      yRef: x['yref'] ?? 'y',
      visibility: x.containsKey('visibility')
          ? ShapeVisibility.values.firstWhere(
              (e) => e.toString() == 'ShapeVisibility.${x['visibility']}',
            )
          : ShapeVisibility.visible,
      fillColor: x.containsKey('fillcolor')
          ? Color(x['fillcolor'] as int)
          : const Color(0x00000000),
     line: x.containsKey('line')
          ? Line(
              color: x['line']['color'] != null
                  ? Color(x['line']['color'] as int)
                  : const Color(0xff000000),
              width: x['line']['width'] != null
                  ? (x['line']['width'] as num).toDouble()
                  : 2.0,
            )
          : null,     
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'x0': x0,
      'y0': y0,
      'x1': x1,
      'y1': y1,
      if (xRef != 'x') 'xref': xRef,
      if (yRef != 'y') 'yref': yRef,
      if (visibility != ShapeVisibility.visible)
        'visibility': visibility.toString().split('.').last,
      if (fillColor.toARGB32() != 0x00000000) 'fillcolor': fillColor.toARGB32(),
      'line': line.toJson(),
    };
  }
}
