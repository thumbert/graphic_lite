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

enum Dash {
  solid,
  dashed,
  dotted,
  longDash,
  dashDot,
  longDashDot;

  /// Converts a [Dash] enum value to a dash-pattern list for [g.BasicLineShape].
  List<double>? dashPattern(Dash dash) => switch (dash) {
    Dash.solid => null,
    Dash.dashed => [6, 4],
    Dash.dotted => [2, 4],
    Dash.longDash => [12, 4],
    Dash.dashDot => [6, 4, 2, 4],
    Dash.longDashDot => [12, 4, 2, 4],
  };
}

enum LineShape {
  /// straight lines between points
  linear,

  /// spline interpolation between points
  spline,

  /// horizontal then vertical
  hv,

  /// vertical then horizontal
  vh,
  // hvh,
  // vhv,
}
