
import 'package:flutter/widgets.dart';
import 'package:graphic_lite/src/display/arrow.dart';
import 'package:graphic_lite/src/display/enums.dart';

/// https://plotly.com/javascript/reference/layout/annotations/
class Annotation {
  /// Creates a text annotation with an optional arrow.
  Annotation({
    required this.text,
    required this.x,
    required this.xRef,
    this.xAnchor = .auto,
    this.xShift = 0,
    required this.y,
    required this.yRef,
    this.yAnchor = .auto,
    this.textAngle = 0,
    this.hoverText,
    this.yShift = 0,
    this.backgroundColor = const Color(0x00000000),
    this.borderColor = const Color(0x00000000),
    this.borderPadding = 1.0,
    this.borderWidth = 1.0,
    this.arrow,
  });

  /// Sets the text associated with this annotation.
  final Text text;

  /// Sets the annotation's x position. If the axis `type` is "log",
  /// then you must take the log of your desired range. If the axis `type`
  /// is "date", it should be date strings, like date data, though DateTime
  /// objects and unix milliseconds will be accepted and converted to strings.
  /// If the axis `type` is "category", it should be numbers, using the scale
  /// where each category is assigned a serial number from zero in the order
  /// it appears.
  final Object x;

  /// Sets the annotation's x coordinate axis. If set to a x axis id (e.g.
  /// "x" or "x2"), the `x` position refers to a x coordinate. If set to
  /// "paper", the `x` position refers to the distance from the left of the
  /// plotting area in normalized coordinates where "0" ("1") corresponds to
  /// the left (right). If set to a x axis ID followed by "domain" (separated
  /// by a space), the position behaves like for "paper", but refers to the
  /// distance in fractions of the domain length from the left of the domain
  /// of that axis: e.g., "x2 domain" refers to the domain of the second x axis
  /// and a x position of 0.5 refers to the point between the left and the
  /// right of the domain of the second x axis.
  final String xRef;

  /// Sets the text box's horizontal position anchor This anchor binds the `x`
  /// position to the "left", "center" or "right" of the annotation. For
  /// example, if `x` is set to 1, `xref` to "paper" and `xanchor` to "right"
  /// then the right-most portion of the annotation lines up with the
  /// right-most edge of the plotting area. If "auto", the anchor is equivalent
  /// to "center" for data-referenced annotations or if there is an arrow,
  /// whereas for paper-referenced with no arrow, the anchor picked corresponds
  /// to the closest side.
  final XAnchor xAnchor;

  /// Shifts the position of the whole annotation and arrow to the right
  /// (positive) or left (negative) by this many pixels.
  final num xShift;

  /// Sets the annotation's y position. If the axis `type` is "log", then you
  /// must take the log of your desired range. If the axis `type` is "date",
  /// it should be date strings, like date data, though DateTime objects and
  /// unix milliseconds will be accepted and converted to strings. If the axis
  /// `type` is "category", it should be numbers, using the scale where each
  /// category is assigned a serial number from zero in the order it appears.
  final Object y;

  /// Sets the annotation's y coordinate axis. If set to a y axis id (e.g. "y"
  /// or "y2"), the `y` position refers to a y coordinate. If set to "paper",
  /// the `y` position refers to the distance from the bottom of the plotting
  /// area in normalized coordinates where "0" ("1") corresponds to the bottom
  /// (top). If set to a y axis ID followed by "domain" (separated by a space),
  /// the position behaves like for "paper", but refers to the distance in
  /// fractions of the domain length from the bottom of the domain of that
  /// axis: e.g., "y2 domain" refers to the domain of the second y axis and a y
  /// position of 0.5 refers to the point between the bottom and the top of the
  /// domain of the second y axis.
  final String yRef;

  /// Sets the text box's vertical position anchor This anchor binds the `y`
  /// position to the "top", "middle" or "bottom" of the annotation. For
  /// example, if `y` is set to 1, `yref` to "paper" and `yanchor` to "top" then
  ///  the top-most portion of the annotation lines up with the top-most edge
  /// of the plotting area. If "auto", the anchor is equivalent to "middle" for
  /// data-referenced annotations or if there is an arrow, whereas for
  /// paper-referenced with no arrow, the anchor picked corresponds to the
  /// closest side.
  final YAnchor yAnchor;

  /// Shifts the position of the whole annotation and arrow up (positive) or
  /// down (negative) by this many pixels.
  final num yShift;

  /// Sets text to appear when hovering over this annotation. If omitted or
  /// blank, no hover label will appear.
  String? hoverText;

  /// Sets the annotation's arrow. If `null`, no arrow is drawn.
  Arrow? arrow;

  /// Sets the angle of the annotation text (in degrees). For example, a
  /// value of 45 would rotate the text 45 degrees clockwise.
  int textAngle;

  /// Sets the background color of the annotation's text. Only applies to the
  /// text itself.
  Color backgroundColor;

  /// Sets the color of the border enclosing the annotation text.
  Color borderColor;

  /// Sets the amount of padding (in px) between the annotation text and the
  /// border of the annotation's bounding box.
  num borderPadding;

  /// Sets the width of the border enclosing the annotation text.
  num borderWidth;
}
