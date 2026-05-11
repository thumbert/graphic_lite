import 'dart:ui';

import '../enums.dart';
import '../marker.dart';

abstract class Trace<D, R> {
  String? name;
  Color? fillColor;
  TraceVisibility visible = TraceVisibility.on;
  late List<D> x;
  late List<R> y;
  late List<String>? text;
  late String xAxis;
  late String yAxis;

  /// Sets the marker for the trace.  A list with only one element means that
  /// the value applies to all elements of the trace. See `Marker` for
  /// more details.
  late List<Marker>? marker;

  /// Determines if the trace shows up in the legend. Note that even if
  /// `showLegend` is true, the trace won't be shown in the legend if it
  /// doesn't have a name or if its visibility is off.
  /// The legend can also be globally disabled in the layout.
  bool showLegend = true;
}
