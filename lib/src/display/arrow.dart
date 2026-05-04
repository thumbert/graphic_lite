import 'dart:ui';

import 'package:graphic_lite/src/display/enums.dart';

class Arrow {
  Arrow({
    this.color = const Color(0xFF000000),
    this.side = .end,
    this.width = 1.0,
    this.headSize = 1.0,
  });
  
  /// Sets the color of the annotation's arrow. 
  Color color;

  /// Sets the size of the head of the annotation's arrow as a multiple of
  /// `arrowWidth`. 
  num headSize;

  /// Sets the side on which the arrow points to the annotation text.
  ArrowSide? side;

  /// Sets the width (in px) of the annotation's arrow.
  num width;

  // TODO: implement ax, ay, axRef, ayRef, axAnchor, ayAnchor
}
