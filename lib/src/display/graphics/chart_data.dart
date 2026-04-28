import 'package:graphic_lite/src/display/enums.dart';
import 'package:graphic_lite/src/display/traces/trace.dart';
import 'package:graphic_lite/src/display/traces/trace_bar.dart';
import 'package:graphic_lite/src/display/traces/trace_scatter.dart';

/// The result returned by [buildChartData].
class ChartDataResult {
  const ChartDataResult({
    required this.data,
    required this.xIsDateTime,
    required this.domainX,
    required this.domainY,
  });

  /// The data list in the format expected by package `graphic`.
  final List<Map<String, dynamic>> data;

  /// Whether the x-axis uses [DateTime] values.
  final bool xIsDateTime;

  /// The full x-axis domain, including 10 % margins.
  final (num, num) domainX;

  /// The full y-axis domain, including 10 % margins.
  final (num, num) domainY;
}

/// Pure function that converts a list of [traces] into the flat data format
/// expected by package `graphic`, and computes x/y axis domains.
///
/// This is the testable core of `_ChartState.makeData`.
ChartDataResult buildChartData(List<Trace> traces) {
  // Pre-compute y_fill for toNextY traces: map from x value → previous trace's y.
  final fillYMaps = <int, Map<Object, double>>{};
  for (var i = 0; i < traces.length; i++) {
    if (traces[i] is ScatterTrace &&
        (traces[i] as ScatterTrace).fill == Fill.toNextY) {
      final yMap = <Object, double>{};
      for (var pi = i - 1; pi >= 0; pi--) {
        if (traces[pi].visible != TraceVisibility.off) {
          for (var j = 0; j < traces[pi].x.length; j++) {
            final yVal = traces[pi].y[j];
            if (yVal is num) yMap[traces[pi].x[j]] = yVal.toDouble();
          }
          break;
        }
      }
      fillYMaps[i] = yMap;
    }
  }

  var minXNum = double.infinity;
  var maxXNum = double.negativeInfinity;
  var minYNum = double.infinity;
  var maxYNum = double.negativeInfinity;
  DateTime? minDt;
  DateTime? maxDt;
  final data = <Map<String, dynamic>>[];

  for (var i = 0; i < traces.length; i++) {
    final trace = traces[i];
    if (trace.visible == TraceVisibility.off) continue;
    for (var j = 0; j < trace.x.length; j++) {
      final xVal = trace.x[j];
      if (xVal is DateTime) {
        if (minDt == null || xVal.isBefore(minDt)) minDt = xVal;
        if (maxDt == null || xVal.isAfter(maxDt)) maxDt = xVal;
      } else if (xVal is num) {
        if (xVal < minXNum) minXNum = xVal.toDouble();
        if (xVal > maxXNum) maxXNum = xVal.toDouble();
      }
      final yVal = trace.y[j];
      if (yVal is num) {
        if (yVal < minYNum) minYNum = yVal.toDouble();
        if (yVal > maxYNum) maxYNum = yVal.toDouble();
      }
      final yFill = (trace is ScatterTrace && trace.fill == Fill.toNextY)
          ? (fillYMaps[i]?[trace.x[j]] ?? 0.0)
          : 0.0;
      final markerForPoint = switch (trace) {
        ScatterTrace s when s.marker != null =>
          s.marker!.length == 1 ? s.marker!.first : s.marker![j],
        BarTrace b when b.marker != null =>
          b.marker!.length == 1 ? b.marker!.first : b.marker![j],
        _ => null,
      };
      data.add({
        'x': trace.x[j],
        'y': trace.y[j],
        if (trace is ScatterTrace && trace.fill != Fill.none) 'y_fill': yFill,
        'name': trace.name ?? 'trace $i',
        if (trace.text != null)
          'text': trace.text!.length == 1
              ? trace.text!.first
              : trace.text![j],
        'marker': markerForPoint,
      });
    }
  }

  bool xIsDateTime;
  (num, num) domainX;
  (num, num) domainY;

  if (minDt != null && maxDt != null) {
    xIsDateTime = true;
    final minMicro = minDt.microsecondsSinceEpoch.toDouble();
    final maxMicro = maxDt.microsecondsSinceEpoch.toDouble();
    final range = maxMicro == minMicro ? 1e6 : maxMicro - minMicro;
    domainX = (minMicro - 0.1 * range, maxMicro + 0.1 * range);
  } else {
    xIsDateTime = false;
    final xRange = maxXNum == minXNum ? 10.0 : maxXNum - minXNum;
    domainX = (minXNum - 0.1 * xRange, maxXNum + 0.1 * xRange);
  }
  final yRange = maxYNum == minYNum ? 10.0 : maxYNum - minYNum;
  domainY = (minYNum - 0.1 * yRange, maxYNum + 0.1 * yRange);

  return ChartDataResult(
    data: data,
    xIsDateTime: xIsDateTime,
    domainX: domainX,
    domainY: domainY,
  );
}
