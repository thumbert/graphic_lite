import 'package:flutter/material.dart';

class Line {
  Line({
    this.color = Colors.transparent,
    this.dash = Dash.solid,
    this.width = 2.0,
    this.shape = LineShape.linear,
  });

  final Color color;
  final Dash dash;
  final num width;
  final LineShape shape;

  Map<String, dynamic> toJson() {
    return {
      'color': color.toARGB32(),
      'dash': dash.toString().split('.').last,
      'width': width,
      'shape': shape.toString().split('.').last,
    };
  }
}

enum Dash { solid, dashed, dotted, longDash, dashDot, longDashDot }

enum LineShape {
  /// straight lines between points
  linear,
  /// spline interpolation between points
  spline,
  /// horizontal then vertical
  hv,
  /// vertical then horizontal
  vh;
  // hvh,
  // vhv,
}

