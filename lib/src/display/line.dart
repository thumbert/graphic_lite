import 'package:flutter/material.dart';

class Line {
  Line({
    this.color = Colors.transparent,
    this.dash = Dash.solid,
    this.width = 2.0,
  });

  final Color color;
  final Dash dash;
  final num width;

  Map<String, dynamic> toJson() {
    return {
      'color': color.toARGB32(),
      'dash': dash.toString().split('.').last,
      'width': width,
    };
  }
}

enum Dash { solid, dashed, dotted, longDash, dashDot, longDashDot }
