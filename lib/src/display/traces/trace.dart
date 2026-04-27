

import 'dart:ui';

import '../enums.dart';

abstract class Trace<D,R> {
  String? name;
  Color? fillColor;
  TraceVisibility visible = TraceVisibility.on;
  late List<D> x;
  late List<R> y;
  late List<String>? text;
  bool showLegend = true;

}