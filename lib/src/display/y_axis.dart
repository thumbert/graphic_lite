import 'package:flutter/animation.dart';
import 'package:graphic_lite/graphic_lite.dart';

/// https://plotly.com/javascript/reference/layout/yaxis/
class YAxis {
  YAxis({Color? color, this.title, this.range, AxisType? type}) {
    this.color ??= YAxis.defaultColor;
    this.type = type ?? AxisType.inferred;
  }

  Color? color;

  /// Sets the domain of this axis (in plot fraction).
  (num, num) domain = (0, 1);

  /// Sets the step in-between ticks on this axis. Use with `tick0`. Must be a
  /// positive number, or special strings available to "log" and "date" axes.
  /// If the axis `type` is "log", then ticks are set every 10^(n"dtick) where
  /// n is the tick number. For example, to set a tick mark at 1, 10, 100, 1000,
  /// ... set dtick to 1. To set tick marks at 1, 100, 10000, ... set
  /// dtick to 2. To set tick marks at 1, 5, 25, 125, 625, 3125, ... set
  /// dtick to log_10(5), or 0.69897000433. "log" has several special values;
  /// "L<f>", where `f` is a positive number, gives ticks linearly spaced in
  /// value (but not position). For example `tick0` = 0.1, `dtick` = "L0.5"
  /// will put ticks at 0.1, 0.6, 1.1, 1.6 etc. To show powers of 10 plus
  /// small digits between, use "D1" (all digits) or "D2" (only 2 and 5).
  /// `tick0` is ignored for "D1" and "D2".
  ///
  /// If the axis `type` is "date", then you must convert the time to
  /// milliseconds. For example, to set the interval between ticks to one day,
  /// set `dtick` to 86400000.0. "date" also has special values "M<n>" gives
  /// ticks spaced by a number of months. `n` must be a positive integer. To set
  /// ticks on the 15th of every third month, set `tick0` to "2000-01-15" and
  /// `dtick` to "M3". To set ticks every 4 years, set `dtick` to "M48"
  ///
  dynamic dTick;

  Color? gridColor;

  num? gridWidth;

  /// Sets the range of this axis.
  ///
  /// If the axis `type` is "log", then you must take the log of your desired
  /// range (e.g. to set the range from 1 to 100, set the range from 0 to 2).
  ///
  /// If the axis `type` is "date", it should be date strings, like date data,
  /// though Date objects and unix milliseconds will be accepted and converted
  /// to strings.
  ///
  /// If the axis `type` is "category", it should be numbers, using the scale
  /// where each category is assigned a serial number from zero in the order
  /// it appears.
  ///
  /// Leaving either or both elements `null` impacts the default `autorange`.
  (num, num)? range;

  /// Determines whether or not grid lines are drawn. If [true], grid lines
  /// are drawn at every tick mark.
  bool showGrid = true;

  /// Determines whether or not this axis is visible. If [false], this axis
  /// will not be displayed.
  bool showLine = false;

  /// Determines whether or not tick labels are drawn. If [false], no tick
  /// labels will be displayed.
  bool showTickLabels = true;

  Side? side;

  /// Sets the placement of the first tick on this axis. Use with `dtick`. 
  /// If the axis `type` is "log", then you must take the log of your 
  /// starting tick (e.g. to set the starting tick to 100, set the `tick0` to 2) 
  /// except when `dtick`="L<f>" (see `dtick` for more info). 
  /// 
  /// If the axis `type` is "date", it should be a date string, like date data.
  ///  
  /// If the axis `type` is "category", it should be a number, using the scale 
  /// where each category is assigned a serial number from zero in the order it 
  /// appears.
  /// 
  dynamic tick0;

  Title? title;

  late final AxisType type;

  static Color get defaultColor => const Color(0xFF444444);

  static Color get defaultGridColor => const Color(0xFFEEEEEE);

  // static XAxis fromJson(Map<String, dynamic> x) {
  //   var out = XAxis();
  //   if (x.containsKey('color')) out.color = Color(x['color']);
  //   if (x.containsKey('domain')) out.domain = (x['domain'][0], x['domain'][1]);
  //   if (x.containsKey('dtick')) out.dTick = x['dtick'];
  //   if (x.containsKey('title')) out.title = x['title'];
  //   if (x.containsKey('range')) out.range = (x['range'][0], x['range'][1]);
  //   return out;
  //  }

  // Map<String, dynamic> toJson() {
  //   return <String, dynamic>{
  //     if (color != defaultColor) 'color': color!.value,
  //     if (domain != const (0, 1)) 'domain': [domain.$1, domain.$2],
  //     if (dTick != null) 'dtick': dTick,
  //     if (title != null) 'title': title,
  //     if (range != null) 'range': [range!.$1, range!.$2],
  //   };
}
