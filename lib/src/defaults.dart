import 'package:flutter/painting.dart';
import 'package:flutter/gestures.dart';
import 'package:graphic/graphic.dart';

class Defaults {
  /// A single primary color.
  static Color primaryColor = const Color(0xFF1F77B4);

  /// A color for auxiliary lines.
  static Color strokeColor = const Color(0xffe8e8e8);

  /// A color for text.
  static Color textColor = const Color(0xff808080);

  static List<Color> get colors => [
    Color(0xFF1F77B4),
    Color(0xFFFF7F0E),
    Color(0xFF2CA02C),
    Color(0xFFD62728),
    Color(0xFF9467BD),
    Color(0xFF8C564B),
    Color(0xFFE377C2),
    Color(0xFF7F7F7F),
    Color(0xFFBCBD22),
    Color(0xFF17BECF),
  ];

  /// A text style for labels.
  static TextStyle get textStyle => TextStyle(fontSize: 14, color: textColor);

  /// A event update for scaling and panning horizontal coordinate range.
  static EventUpdater<List<double>> get horizontalRangeEvent =>
      _getRangeUpdate(true, false);

  /// A event update for scaling and panning vertical coordinate range.
  static EventUpdater<List<double>> get verticalRangeEvent =>
      _getRangeUpdate(false, false);

  /// A event update for scaling and panning horizontal coordinate range by cursor focus.
  static EventUpdater<List<double>> get horizontalRangeFocusEvent =>
      _getRangeUpdate(true, true);

  /// A event update for scaling and panning vertical coordinate range by cursor focus.
  static EventUpdater<List<double>> get verticalRangeFocusEvent =>
      _getRangeUpdate(false, true);
}

/// Gets event update for different dimensions.
EventUpdater<List<double>> _getRangeUpdate(
  bool isHorizontal,
  bool focusMouseScale,
) => (List<double> init, List<double> pre, Event event) {
  print('init: $init, pre: $pre, event: $event');
  if (event is GestureEvent) {
    final gesture = event.gesture;

    if (gesture.type == GestureType.scaleEnd) {
      print('gesture type: ${gesture.type}, details: ${gesture.details}');
      print(
        'localMoveStart: ${gesture.localMoveStart}, localPosition: ${gesture.localPosition}',
      );
      // final detail = gesture.details as ScaleEndDetails;
      // return [0.2, 0.4];
      return [0.0, 1.0];

      // Scaling.

      // double getScaleDim(ScaleUpdateDetails p0) =>
      //     isHorizontal ? p0.horizontalScale : p0.verticalScale;
      // final preScale = getScaleDim(gesture.preScaleDetail!);
      // final scale = getScaleDim(detail);
      // final deltaRatio = (scale - preScale) / preScale / 2;
      // final preRange = pre.last - pre.first;
      // final delta = deltaRatio * preRange;
      // return [pre.first - delta, pre.last + delta];
    } else if (gesture.type == GestureType.scaleUpdate) {
      // final detail = gesture.details as ScaleUpdateDetails;

      // if (detail.pointerCount == 1) {
      //   // Panning.

      //   final deltaRatio = isHorizontal
      //       ? gesture.preScaleDetail!.focalPointDelta.dx
      //       : -gesture.preScaleDetail!.focalPointDelta.dy;
      //   final delta =
      //       deltaRatio /
      //       (isHorizontal ? gesture.chartSize.width : gesture.chartSize.height);
      //   return [pre.first + delta, pre.last + delta];
      // } else {
      //   // Scaling.

      //   double getScaleDim(ScaleUpdateDetails p0) =>
      //       isHorizontal ? p0.horizontalScale : p0.verticalScale;
      //   final preScale = getScaleDim(gesture.preScaleDetail!);
      //   final scale = getScaleDim(detail);
      //   final deltaRatio = (scale - preScale) / preScale / 2;
      //   final preRange = pre.last - pre.first;
      //   final delta = deltaRatio * preRange;
      //   return [pre.first - delta, pre.last + delta];
      // }
    } else if (gesture.type == GestureType.scroll) {
      const step = -0.1;
      final scrollDelta = gesture.details as Offset;
      final deltaRatio = scrollDelta.dy == 0
          ? 0.0
          : scrollDelta.dy > 0
          ? (step / 2)
          : (-step / 2);
      final preRange = pre.last - pre.first;
      final delta = deltaRatio * preRange;
      if (!focusMouseScale) {
        return [pre.first - delta, pre.last + delta];
      } else {
        double mousePos;
        if (isHorizontal) {
          mousePos =
              (gesture.localPosition.dx - 39.5) /
              (gesture.chartSize.width - 51);
        } else {
          mousePos =
              1 -
              (gesture.localPosition.dy - 5) / (gesture.chartSize.height - 25);
        }
        mousePos = (mousePos - pre.first) / (pre.last - pre.first);
        return [
          pre.first - delta * 2 * mousePos,
          pre.last + delta * 2 * (1 - mousePos),
        ];
      }
    } else if (gesture.type == GestureType.doubleTap) {
      return init;
    }
  }

  return pre;
};
