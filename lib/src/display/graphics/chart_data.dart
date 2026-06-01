import 'package:graphic_lite/src/display/enums.dart';
import 'package:graphic_lite/src/display/layout.dart';
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
    required this.hasFill,
    this.hasBarWidths = false,
    this.hasHorizontalBars = false,
  });

  /// The data list in the format expected by package `graphic`.
  final List<Map<String, dynamic>> data;

  /// Whether the x-axis uses [DateTime] values.
  final bool xIsDateTime;

  /// The full x-axis domain, including 10 % margins.
  final (num, num) domainX;

  /// The full y-axis domain, including 10 % margins.
  final (num, num) domainY;

  /// Whether any [ScatterTrace] has a non-null, non-[Fill.none] fill that
  /// requires the `y_fill` variable and [AreaMark] to be present.
  final bool hasFill;

  /// Whether any [BarTrace] has individual widths set, requiring `x_start`
  /// and `x_end` variables for range-based position encoding.
  final bool hasBarWidths;

  /// Whether any [BarTrace] has [Orientation.horizontal].
  final bool hasHorizontalBars;
}

/// Pure function that converts a list of [traces] into the flat data format
/// expected by package `graphic`, and computes x/y axis domains.
///
/// [layout] is the chart layout configuration. When [Layout.barMode] is
/// [BarMode.stack], the y-axis domain is based on per-category stacked totals
/// rather than individual bar values.
///
/// This is the testable core of `_ChartState.makeData`.
ChartDataResult buildChartData(List<Trace> traces, {Layout? layout}) {
  final barMode = layout?.barMode;
  // Determine whether any scatter trace needs area fill.
  final hasFill = traces.any(
    (t) =>
        t is ScatterTrace &&
        t.fill != Fill.none &&
        t.visible != TraceVisibility.off,
  );

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
  bool hasBarWidths = false;
  bool hasHorizontalBars = false;

  // For stacked bars, accumulate per-category sums to find the true y range.
  final stackedSums = <Object, double>{};
  if (barMode == BarMode.stack) {
    for (final trace in traces) {
      if (trace is! BarTrace || trace.visible == TraceVisibility.off) continue;
      for (var j = 0; j < trace.x.length; j++) {
        final xKey = trace.x[j];
        final yVal = trace.y[j];
        if (yVal is num) {
          stackedSums[xKey] = (stackedSums[xKey] ?? 0.0) + yVal.toDouble();
        }
      }
    }
  }

  for (var i = 0; i < traces.length; i++) {
    final trace = traces[i];
    if (trace.visible == TraceVisibility.off) continue;
    for (var j = 0; j < trace.x.length; j++) {
      final isHorizontalBar =
          trace is BarTrace && trace.orientation == Orientation.horizontal;
      final xVal = trace.x[j];
      if (xVal is DateTime) {
        if (minDt == null || xVal.isBefore(minDt)) minDt = xVal;
        if (maxDt == null || xVal.isAfter(maxDt)) maxDt = xVal;
      } else if (xVal is num) {
        // For horizontal bars, trace.x contains bar values (→ 'y' after swap).
        // Track in minXNum/maxXNum for _domainX reference; also update y-domain.
        if (xVal < minXNum) minXNum = xVal.toDouble();
        if (xVal > maxXNum) maxXNum = xVal.toDouble();
        if (isHorizontalBar) {
          // Bar values become 'y' after swap — track in y-domain.
          if (xVal < minYNum) minYNum = xVal.toDouble();
          if (xVal > maxYNum) maxYNum = xVal.toDouble();
        }
        // For VERTICAL bars with a width, expand the x domain to include bar edges.
        if (trace is BarTrace && trace.width != null && !isHorizontalBar) {
          final w =
              (trace.width!.length == 1 ? trace.width!.first : trace.width![j])
                  .toDouble();
          final xStart = xVal.toDouble() - w / 2;
          final xEnd = xVal.toDouble() + w / 2;
          if (xStart < minXNum) minXNum = xStart;
          if (xEnd > maxXNum) maxXNum = xEnd;
        }
      }
      if (isHorizontalBar) {
        hasHorizontalBars = true;
      }
      final yVal = trace.y[j];
      // For horizontal bars, trace.y contains category strings (→ 'x' after swap);
      // skip numeric y-domain tracking (handled above via trace.x).
      if (yVal is num && !isHorizontalBar) {
        if (yVal < minYNum) minYNum = yVal.toDouble();
        if (yVal > maxYNum) maxYNum = yVal.toDouble();
      }
      final needsFill = trace is ScatterTrace && trace.fill != Fill.none;
      final yFill = needsFill && trace.fill == Fill.toNextY
          ? (fillYMaps[i]?[trace.x[j]])
          : null;
      final markerForPoint = switch (trace) {
        ScatterTrace s when s.marker != null =>
          s.marker!.length == 1 ? s.marker!.first : s.marker![j],
        BarTrace b when b.marker != null =>
          b.marker!.length == 1 ? b.marker!.first : b.marker![j],
        _ => null,
      };

      // Individual bar widths/heights: store as bar_width (data units) for
      // per-point size encoding.  For horizontal bars, this is the bar height
      // (thickness) in y-axis units; for vertical bars it is the bar width in
      // x-axis units.
      num? barWidth;
      if (trace is BarTrace && trace.width != null) {
        hasBarWidths = true;
        barWidth = trace.width!.length == 1
            ? trace.width!.first
            : trace.width![j];
      }

      data.add({
        // For horizontal bars, swap x/y: 'x' = category (String), 'y' = value (num).
        'x': isHorizontalBar ? trace.y[j] : trace.x[j],
        'y': isHorizontalBar ? trace.x[j] : trace.y[j],
        if (needsFill) 'y_fill': yFill,
        'name': trace.name ?? 'trace $i',
        if (trace.text != null)
          'text': trace.text!.length == 1 ? trace.text!.first : trace.text![j],
        'marker': markerForPoint,
        'bar_width': ?barWidth,
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
  if (stackedSums.isNotEmpty) {
    minYNum = 0.0;
    maxYNum = stackedSums.values.reduce((a, b) => a > b ? a : b);
  }
  if (minYNum == double.infinity) {
    domainY = (0.0, 1.0);
  } else if (hasHorizontalBars) {
    // For horizontal bars the value domain must include 0 so bars start at the
    // left plot edge. Use min(0, minYNum) as the lower bound.
    final effectiveMin = minYNum < 0 ? minYNum : 0.0;
    final yRange = maxYNum - effectiveMin;
    domainY = (effectiveMin, maxYNum + 0.1 * (yRange == 0 ? 10.0 : yRange));
  } else {
    final yRange = maxYNum == minYNum ? 10.0 : maxYNum - minYNum;
    domainY = (minYNum - 0.1 * yRange, maxYNum + 0.1 * yRange);
  }

  return ChartDataResult(
    hasFill: hasFill,
    hasBarWidths: hasBarWidths,
    hasHorizontalBars: hasHorizontalBars,
    data: data,
    xIsDateTime: xIsDateTime,
    domainX: domainX,
    domainY: domainY,
  );
}
