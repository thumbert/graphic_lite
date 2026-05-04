import 'dart:ui';

import 'package:graphic_lite/src/display/enums.dart';

class Arrow {
  Arrow({
    this.color = const Color(0xFF000000),
    required this.ax,
    required this.ay,
    this.side = .end,
    this.width = 1.0,
    this.headSize = 1.0,
    this.axRef = 'pixel',
    this.ayRef = 'pixel',
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

  /// Sets the x component of the arrow tail about the arrow head. If `axref` is
  /// `pixel`, a positive (negative) component corresponds to an arrow pointing
  /// from right to left (left to right). If `axref` is not `pixel` and is
  /// exactly the same as `xref`, this is an absolute value on that axis,
  /// like `x`, specified in the same coordinates as `xref`.
  num ax;

  /// Indicates in what coordinates the tail of the annotation (ax,ay) is
  /// specified. If set to a x axis id (e.g. "x" or "x2"), the `x` position
  /// refers to a x coordinate. If set to "paper", the `x` position refers to
  /// the distance from the left of the plotting area in normalized coordinates
  /// where "0" ("1") corresponds to the left (right). If set to a x axis ID
  /// followed by "domain" (separated by a space), the position behaves like
  /// for "paper", but refers to the distance in fractions of the domain length
  /// from the left of the domain of that axis: e.g., "x2 domain" refers to
  /// the domain of the second x axis and a x position of 0.5 refers to the
  /// point between the left and the right of the domain of the second x axis.
  /// In order for absolute positioning of the arrow to work, "axref" must be
  /// exactly the same as "xref", otherwise "axref" will revert to "pixel"
  /// (explained next). For relative positioning, "axref" can be set to
  /// "pixel", in which case the "ax" value is specified in pixels relative to
  /// "x". Absolute positioning is useful for trendline annotations which
  /// should continue to indicate the correct trend when zoomed. Relative
  /// positioning is useful for specifying the text offset for an annotated
  /// point.
  String axRef;

  /// Sets the y component of the arrow tail about the arrow head. If `ayref`
  /// is `pixel`, a positive (negative) component corresponds to an arrow
  /// pointing from bottom to top (top to bottom). If `ayref` is not `pixel`
  /// and is exactly the same as `yref`, this is an absolute value on that axis,
  /// like `y`, specified in the same coordinates as `yref`.
  num ay;

  /// Indicates in what coordinates the tail of the annotation (ax,ay) is 
  /// specified. If set to a y axis id (e.g. "y" or "y2"), the `y` position 
  /// refers to a y coordinate. If set to "paper", the `y` position refers to 
  /// the distance from the bottom of the plotting area in normalized 
  /// coordinates where "0" ("1") corresponds to the bottom (top). If set to a 
  /// y axis ID followed by "domain" (separated by a space), the position 
  /// behaves like for "paper", but refers to the distance in fractions of 
  /// the domain length from the bottom of the domain of that axis: e.g., 
  /// "y2 domain" refers to the domain of the second y axis and a y position 
  /// of 0.5 refers to the point between the bottom and the top of the domain 
  /// of the second y axis. In order for absolute positioning of the arrow to 
  /// work, "ayref" must be exactly the same as "yref", otherwise "ayref" will 
  /// revert to "pixel" (explained next). For relative positioning, "ayref" can 
  /// be set to "pixel", in which case the "ay" value is specified in pixels 
  /// relative to "y". Absolute positioning is useful for trendline annotations 
  /// which should continue to indicate the correct trend when zoomed. Relative 
  /// positioning is useful for specifying the text offset for an annotated 
  /// point.
  String ayRef;

}
