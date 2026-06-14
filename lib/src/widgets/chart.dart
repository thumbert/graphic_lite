import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:graphic_lite/graphic_lite.dart';
import 'package:graphic/graphic.dart' as g;
import 'package:graphic_lite/src/display/graphics/chart_data.dart';
import 'package:graphic_lite/src/display/graphics/chart_variables.dart';
import 'package:graphic_lite/src/widgets/line_shape_vh.dart';
import 'annotations_painter.dart';
import 'shapes_painter.dart';

/// A [CustomPainter] that draws a dashed/dotted line for the legend swatch.
class _LegendLinePainter extends CustomPainter {
  const _LegendLinePainter({
    required this.color,
    required this.strokeWidth,
    this.dash,
  });

  final Color color;
  final double strokeWidth;
  final List<double>? dash;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    final dashList = dash;
    if (dashList == null || dashList.isEmpty) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    double x = 0;
    int di = 0;
    bool drawing = true;
    while (x < size.width) {
      final len = dashList[di % dashList.length];
      final end = (x + len).clamp(0.0, size.width);
      if (drawing) {
        canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      }
      x = end;
      di++;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(_LegendLinePainter old) =>
      color != old.color || strokeWidth != old.strokeWidth || dash != old.dash;
}

/// Configuration for a single subplot panel.  Used internally by [_ChartState]
/// when the layout has a [Grid] or multiple x-axes.
class _SubplotSpec {
  const _SubplotSpec({
    required this.xAxisId,
    required this.yAxisId,
    required this.xDomain,
    required this.yDomain,
    required this.traces,
  });

  /// E.g. 'x', 'x2', 'x3', …
  final String xAxisId;

  /// E.g. 'y', 'y2', 'y3', …
  final String yAxisId;

  /// Normalized [0, 1] horizontal extent of this subplot (0 = left, 1 = right).
  final (num, num) xDomain;

  /// Normalized [0, 1] vertical extent of this subplot (0 = bottom, 1 = top).
  final (num, num) yDomain;

  final List<Trace> traces;
}

class Chart extends StatefulWidget {
  Chart({super.key, required this.traces, Layout? layout})
    : layout = layout ?? Layout.getDefault() {
    for (var i = 0; i < traces.length; i++) {
      traces[i].name ??= 'trace $i';
    }
  }

  final List<Trace> traces;
  final Layout layout;

  @override
  State<Chart> createState() => _ChartState();
}

class _ChartState extends State<Chart> {
  final GlobalKey _chartKey = GlobalKey();

  /// The full dataset constructed from the input [traces], stored as a list of
  /// maps (in the format package `graphic` wants.)
  ///
  /// Each map represents a data point with keys like 'x', 'y', and 'name'.
  /// This is generated in the build method by [makeData] and used for rendering
  /// the chart and handling selections.
  ///
  /// This is stored as a state variable because it is needed in the gesture
  /// handling logic to filter data points based on user interactions
  /// (like drag selection).
  late List<Map<String, dynamic>> data;
  bool _hasFill = false;
  bool _hasBarWidths = false;
  bool _hasHorizontalBars = false;

  // Cursor position updated on every hover event (no setState — used only in
  // _tooltipRenderer which runs synchronously after the gesture is processed).
  Offset _hoverLocalPosition = Offset.zero;

  (num, num)? _filteredDomainX;
  (num, num)? _filteredDomainY;

  final StreamController<g.GestureEvent> _gestureController =
      StreamController<g.GestureEvent>.broadcast();
  StreamSubscription<g.GestureEvent>? _gestureSub;
  Offset? _dragStart;
  List<Map<String, dynamic>> _filteredData = [];
  List<double>? _currentSelectionNormalized;

  // Per-subplot gesture controllers and hover positions (keyed by
  // '${xAxisId}_${yAxisId}', e.g. 'x_y', 'x2_y2').
  final Map<String, StreamController<g.GestureEvent>>
  _subplotGestureControllers = {};
  final Map<String, Offset> _subplotHoverPositions = {};

  @override
  void initState() {
    super.initState();
    _gestureSub = _gestureController.stream.listen((event) {
      try {
        final geg = event.gesture;

        if (geg.type == g.GestureType.scaleStart) {
          final details = geg.details as ScaleStartDetails;
          final chartBox =
              _chartKey.currentContext?.findRenderObject() as RenderBox?;
          if (chartBox == null) return;
          // store local chart coordinates for the drag start
          _dragStart = chartBox.globalToLocal(details.focalPoint);
          // start live selection
          setState(() {
            _currentSelectionNormalized = null;
          });
        } else if (geg.type == g.GestureType.scaleUpdate &&
            _dragStart != null) {
          // live update of selection while dragging
          final chartBox =
              _chartKey.currentContext?.findRenderObject() as RenderBox?;
          if (chartBox == null) return;
          final localEnd = geg.localPosition;
          const leftPad = 40.0;
          const rightPad = 10.0;
          final localStart = _dragStart!;
          final left = localStart.dx < localEnd.dx
              ? localStart.dx
              : localEnd.dx;
          final right = localStart.dx < localEnd.dx
              ? localEnd.dx
              : localStart.dx;
          final width = chartBox.size.width - leftPad - rightPad;
          if (width <= 0) return;
          double nx0 = ((left - leftPad) / width).clamp(0.0, 1.0);
          double nx1 = ((right - leftPad) / width).clamp(0.0, 1.0);
          if (nx1 <= nx0) return;
          setState(() {
            _currentSelectionNormalized = [nx0, nx1];
          });
        } else if (geg.type == g.GestureType.scaleEnd && _dragStart != null) {
          final chartBox =
              _chartKey.currentContext?.findRenderObject() as RenderBox?;
          if (chartBox == null) return;

          // gesture.localPosition is already local to the chart
          final localEnd = geg.localPosition;
          // print('Drag ended at local position: $localEnd');

          // Adjust these paddings to match your chart layout if needed.
          const leftPad = 40.0;
          const rightPad = 10.0;
          final localStart = _dragStart!;
          final left = localStart.dx < localEnd.dx
              ? localStart.dx
              : localEnd.dx;
          final right = localStart.dx < localEnd.dx
              ? localEnd.dx
              : localStart.dx;
          final width = chartBox.size.width - leftPad - rightPad;
          if (width <= 0) return;
          // print('Chart width for selection: $width');
          // print('Raw selection range in local coordinates: [$left, $right]');

          double nx0 = ((left - leftPad) / width).clamp(0.0, 1.0);
          double nx1 = ((right - leftPad) / width).clamp(0.0, 1.0);
          if (nx1 <= nx0) return;

          final firstMs = _domainX.$1;
          final lastMs = _domainX.$2;
          // print('Selected normalized range: [$nx0, $nx1]');
          // print('Domain X: [${_domainX.$1}, ${_domainX.$2}]');

          final selMin = firstMs + nx0 * (lastMs - firstMs);
          final selMax = firstMs + nx1 * (lastMs - firstMs);
          // print('Selected domain range: [$selMin, $selMax]');

          setState(() {
            _filteredData = data.where((e) {
              final xNum = _xIsDateTime
                  ? (e['x'] as DateTime).microsecondsSinceEpoch.toDouble()
                  : (e['x'] as num).toDouble();
              return xNum >= selMin && xNum <= selMax;
            }).toList();
            if (_filteredData.isNotEmpty) {
              // X range = exact selection bounds; Y range = data extent of filtered points.
              _filteredDomainX = (selMin, selMax);
              _filteredDomainY = _computeYDomainFromData(_filteredData);
            }
            // clear live selection overlay once selection is committed
            _currentSelectionNormalized = null;
          });

          _dragStart = null;
        } else if (geg.type == g.GestureType.doubleTap) {
          setState(() {
            _filteredData = [];
            _filteredDomainX = null;
            _filteredDomainY = null;
            _currentSelectionNormalized = null;
          });
        } else if (geg.type == g.GestureType.hover) {
          // Track cursor position for stacked-bar tooltip hit-testing.
          _hoverLocalPosition = geg.localPosition;
        }
      } catch (err) {
        // swallow any cast errors or runtime hiccups during gesture handling
      }
    });
  }

  @override
  void dispose() {
    _gestureSub?.cancel();
    _gestureController.close();
    for (final ctrl in _subplotGestureControllers.values) {
      ctrl.close();
    }
    super.dispose();
  }

  /// Use the input [traces] to construct the data in the format that package
  /// `graphic` expects.
  ///
  /// Whether the x-axis uses DateTime values (affects domain/filter logic).
  bool _xIsDateTime = false;

  late (num, num) _domainX;
  late (num, num) _domainY;

  /// Y domain for the secondary (y2) axis. Only valid when [_hasSecondaryYAxis].
  late (num, num) _domainY2;

  /// Flattened data for secondary-axis traces (those with yAxis == 'y2').
  List<Map<String, dynamic>> _dataSecondary = [];

  /// True when the layout defines a secondary y-axis and at least one trace
  /// is assigned to it.
  bool get _hasSecondaryYAxis =>
      widget.layout.yAxis2 != null && widget.traces.any((t) => t.yAxis == 'y2');

  (num, num) _computeYDomainFromData(List<Map<String, dynamic>> points) {
    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    for (final e in points) {
      final yVal = e['y'];
      if (yVal is num) {
        if (yVal < minY) minY = yVal.toDouble();
        if (yVal > maxY) maxY = yVal.toDouble();
      }
    }
    final yRange = maxY == minY ? 1.0 : maxY - minY;
    return (minY - 0.1 * yRange, maxY + 0.1 * yRange);
  }

  /// Prepare the data for [graphics].
  ///
  /// Delegates to [buildChartData] and updates the domain/type fields as a
  /// side effect so the rest of the widget can reference them.
  ///
  /// When a secondary y-axis is present, primary and secondary traces are
  /// split so each gets its own y domain. [_dataSecondary] is populated with
  /// the secondary trace data points.
  List<Map<String, dynamic>> makeData(List<Trace> traces) {
    if (_hasSecondaryYAxis) {
      final primaryTraces = traces.where((t) => t.yAxis != 'y2').toList();
      final secondaryTraces = traces.where((t) => t.yAxis == 'y2').toList();

      // Use all traces to establish the shared x domain.
      final allResult = buildChartData(traces, layout: widget.layout);
      _xIsDateTime = allResult.xIsDateTime;
      _domainX = allResult.domainX;

      final primaryResult = buildChartData(
        primaryTraces,
        layout: widget.layout,
      );
      _domainY = primaryResult.domainY;
      _hasFill = primaryResult.hasFill;
      _hasBarWidths = primaryResult.hasBarWidths;
      _hasHorizontalBars = primaryResult.hasHorizontalBars;

      final secondaryResult = buildChartData(
        secondaryTraces,
        layout: widget.layout,
      );
      _domainY2 = secondaryResult.domainY;
      _dataSecondary = secondaryResult.data;

      return primaryResult.data;
    } else {
      final result = buildChartData(traces, layout: widget.layout);
      _xIsDateTime = result.xIsDateTime;
      _domainX = result.domainX;
      _domainY = result.domainY;
      _hasFill = result.hasFill;
      _hasBarWidths = result.hasBarWidths;
      _hasHorizontalBars = result.hasHorizontalBars;
      _dataSecondary = [];
      return result.data;
    }
  }

  /// Variables for the chart as needed by package `graphic`.
  ///
  /// Delegates to [buildChartVariables]. When [domainX] / [domainY] are
  /// provided, explicit axis scales are set so the chart shows exactly the
  /// selected range; otherwise the full data domain computed by [makeData] is
  /// used.
  Map<String, g.Variable<Map<dynamic, dynamic>, dynamic>> makeVariables(
    List<Map<String, dynamic>> data, {
    (num, num)? domainX,
    (num, num)? domainY,
  }) {
    return buildChartVariables(
      data,
      domainX: domainX ?? _domainX,
      domainY: domainY ?? _domainY,
      includeYFill: _hasFill,
      includeBarRange: _hasBarWidths,
    );
  }

  /// Variables for the secondary y-axis chart.
  ///
  /// Always uses an explicit x domain equal to the primary chart's x domain so
  /// both charts' plot areas stay perfectly aligned.
  Map<String, g.Variable<Map<dynamic, dynamic>, dynamic>>
  makeVariablesSecondary(List<Map<String, dynamic>> data) {
    return buildChartVariables(
      data,
      domainX: _filteredDomainX ?? _domainX,
      domainY: _domainY2,
    );
  }

  /// Returns true if [_hoverLocalPosition] is inside the canvas rectangle of
  /// the bar identified by [traceName] and [xVal] for the given chart [size].
  ///
  /// Handles all [BarMode]s:
  ///   - single / stack : bar is centred on its category band.
  ///   - group          : bar position is offset by the dodge geometry.
  ///   - stack          : y bounds are the cumulative stacked range.
  bool _isCursorOverBar(String traceName, Object xVal, Size size) {
    final barTraces = widget.traces.whereType<BarTrace>().toList();
    if (barTraces.isEmpty) return false;

    const leftPad = 40.0, rightPad = 10.0, topPad = 5.0, bottomPad = 40.0;
    final plotW = size.width - leftPad - rightPad;
    final plotH = size.height - topPad - bottomPad;

    // Build ordered category list.
    final categories = <Object>[];
    for (final trace in barTraces) {
      for (final xv in trace.x) {
        if (!categories.contains(xv)) categories.add(xv);
      }
    }
    final nCategories = categories.length;
    final nGroups = barTraces.length;
    final barGap = widget.layout.barGap.toDouble();
    final barGroupGap = widget.layout.barGroupGap.toDouble();
    final barMode = widget.layout.barMode;

    final c = categories.indexOf(xVal);
    if (c < 0) return false;

    final band = 1.0 / nCategories;
    final catNormX = (c + 0.5) * band;

    // ── canvas x bounds ───────────────────────────────────────────────────
    final double barNormX;
    final double barHalfWidthNorm;

    // Check if the matched trace has individual widths for this x value.
    final matchedTrace = barTraces.firstWhere(
      (t) => (t.name ?? '') == traceName,
      orElse: () => barTraces.first,
    );
    final matchedIdx = matchedTrace.x.indexWhere((v) => v == xVal);
    if (matchedTrace.width != null && matchedIdx >= 0 && xVal is num) {
      // Per-bar width: convert from data units to normalised [0,1] coordinates.
      final w =
          (matchedTrace.width!.length == 1
                  ? matchedTrace.width!.first
                  : matchedTrace.width![matchedIdx])
              .toDouble();
      final xRange = (_domainX.$2 - _domainX.$1).toDouble();
      final normX = (xVal.toDouble() - _domainX.$1) / xRange;
      barNormX = normX;
      barHalfWidthNorm = xRange > 0 ? (w / 2) / xRange : 0;
    } else if (barMode == BarMode.group) {
      final traceIdx = barTraces.indexWhere((t) => (t.name ?? '') == traceName);
      if (traceIdx < 0) return false;
      final ratio = (1 - barGap) / nGroups;
      final bias = ratio * band;
      final accumulatedStart = -bias * (nGroups - 1) / 2.0;
      barNormX = catNormX + accumulatedStart + traceIdx * bias;
      barHalfWidthNorm = (1 - barGroupGap) * bias / 2.0;
    } else {
      barNormX = catNormX;
      barHalfWidthNorm = (1 - barGap) * band / 2.0;
    }
    final barCanvasX = leftPad + barNormX * plotW;
    final barHalfWidthPx = barHalfWidthNorm * plotW;
    if ((_hoverLocalPosition.dx - barCanvasX).abs() > barHalfWidthPx) {
      return false;
    }

    // ── canvas y bounds ───────────────────────────────────────────────────
    final barTrace = barTraces.firstWhere(
      (t) => (t.name ?? '') == traceName,
      orElse: () => barTraces.first,
    );
    final idx = barTrace.x.indexWhere((v) => v == xVal);
    if (idx < 0) return false;
    final barY = (barTrace.y[idx] as num).toDouble();

    double yDataBottom, yDataTop;
    if (barMode == BarMode.stack) {
      double cumBottom = 0.0;
      yDataBottom = 0.0;
      yDataTop = barY;
      for (final bt in barTraces) {
        if (bt.visible == TraceVisibility.off) continue;
        final btIdx = bt.x.indexWhere((v) => v == xVal);
        if (btIdx < 0) continue;
        final btY = (bt.y[btIdx] as num).toDouble();
        if ((bt.name ?? '') == traceName) {
          yDataBottom = cumBottom;
          yDataTop = cumBottom + btY;
          break;
        }
        cumBottom += btY;
      }
    } else {
      yDataBottom = barY < 0 ? barY : 0.0;
      yDataTop = barY < 0 ? 0.0 : barY;
    }

    final domainSpan = (_domainY.$2 - _domainY.$1).toDouble();
    final canvasYTop =
        topPad + (1.0 - (yDataTop - _domainY.$1) / domainSpan) * plotH;
    final canvasYBottom =
        topPad + (1.0 - (yDataBottom - _domainY.$1) / domainSpan) * plotH;

    final cy = _hoverLocalPosition.dy;
    return cy >= canvasYTop && cy <= canvasYBottom;
  }

  /// Returns true when [_hoverLocalPosition] is within [testRadius] pixels of
  /// the canvas coordinates of the scatter point ([xVal], [yVal]).
  bool _isCursorNearScatterPoint(Object? xVal, Object? yVal, Size size) {
    const testRadius = 15.0;
    const leftPad = 40.0;
    const rightPad = 10.0;
    const topPad = 5.0;
    const bottomPad = 40.0;
    final plotW = size.width - leftPad - rightPad;
    final plotH = size.height - topPad - bottomPad;

    double xNum;
    if (xVal is DateTime) {
      xNum = xVal.microsecondsSinceEpoch.toDouble();
    } else if (xVal is num) {
      xNum = xVal.toDouble();
    } else {
      return false;
    }
    final yNum = yVal is num ? yVal.toDouble() : 0.0;

    final normX = (_domainX.$2 == _domainX.$1)
        ? 0.5
        : (xNum - _domainX.$1) / (_domainX.$2 - _domainX.$1);
    final normY = (_domainY.$2 == _domainY.$1)
        ? 0.5
        : (yNum - _domainY.$1) / (_domainY.$2 - _domainY.$1);

    final canvasX = leftPad + normX * plotW;
    final canvasY = topPad + (1.0 - normY) * plotH;

    final dx = _hoverLocalPosition.dx - canvasX;
    final dy = _hoverLocalPosition.dy - canvasY;
    return dx * dx + dy * dy <= testRadius * testRadius;
  }

  /// Custom tooltip renderer that colors the tooltip text to match the
  /// corresponding trace color.
  List<g.MarkElement> _tooltipRenderer(
    Size size,
    Offset anchor,
    Map<int, g.Tuple> selectedTuples,
  ) {
    if (selectedTuples.isEmpty && !_hasBarWidths && !_hasHorizontalBars)
      return [];

    // When bars have individual widths the graphic library's PointSelection
    // uses nearest-centroid logic, which picks the wrong bar whenever the
    // cursor is inside a wide bar but closer to a different bar's centroid.
    // Bypass selectedTuples entirely and hit-test against each bar's actual
    // x/y extents using the cursor position and the data list directly.
    if (_hasBarWidths && !_hasHorizontalBars) {
      const leftPad = 40.0, rightPad = 10.0, topPad = 5.0, bottomPad = 40.0;
      final plotW = size.width - leftPad - rightPad;
      final plotH = size.height - topPad - bottomPad;
      final xRange = (_domainX.$2 - _domainX.$1).toDouble();
      final yRange = (_domainY.$2 - _domainY.$1).toDouble();
      final cursorDataX =
          _domainX.$1 + ((_hoverLocalPosition.dx - leftPad) / plotW) * xRange;
      final cursorDataY =
          _domainY.$1 +
          ((1.0 - (_hoverLocalPosition.dy - topPad) / plotH)) * yRange;

      final activeData = _filteredData.isNotEmpty ? _filteredData : data;
      Map<String, dynamic>? hitRow;
      for (final row in activeData) {
        if (!row.containsKey('bar_width')) continue;
        final xVal = row['x'];
        if (xVal is! num) continue;
        final w = (row['bar_width'] as num).toDouble();
        if (cursorDataX < xVal - w / 2 || cursorDataX > xVal + w / 2) continue;
        final yVal = (row['y'] as num).toDouble();
        final yBottom = yVal < 0 ? yVal : 0.0;
        final yTop = yVal < 0 ? 0.0 : yVal;
        if (cursorDataY < yBottom || cursorDataY > yTop) continue;
        hitRow = row;
        break;
      }
      if (hitRow == null) return [];
      return _buildTooltipElements(size, hitRow, anchor);
    }

    // Horizontal bar hit-testing: with transposed coord, screen-x maps to the
    // value axis ('y' after data-swap) and screen-y maps to the category axis
    // ('x' after data-swap).
    if (_hasHorizontalBars) {
      const leftPad = 40.0, rightPad = 10.0, topPad = 5.0, bottomPad = 40.0;
      final plotW = size.width - leftPad - rightPad;
      final plotH = size.height - topPad - bottomPad;
      // With transposed coord and data-swap: screen-x → value axis → use _domainY.
      final yRange = (_domainY.$2 - _domainY.$1).toDouble();
      final cursorDataValue =
          _domainY.$1 + ((_hoverLocalPosition.dx - leftPad) / plotW) * yRange;
      // screen-y: graphic y-axis goes bottom→top so normY = 1 - normScreenY.
      final normScreenY =
          (_hoverLocalPosition.dy - topPad).clamp(0.0, plotH) / plotH;
      final normY = 1.0 - normScreenY; // 0 = bottom, 1 = top

      final barTraces = widget.traces.whereType<BarTrace>().toList();
      // Collect unique categories (from trace.y, still holds categories) in order.
      final categories = <Object>[];
      for (final t in barTraces) {
        for (final yv in t.y) {
          if (!categories.contains(yv)) categories.add(yv);
        }
      }
      final n = categories.length;
      if (n == 0) return [];

      // Discrete scale: category i center is at (i + 0.5) / n.
      final barGap = widget.layout.barGap.toDouble();
      final halfBandNorm = (1 - barGap) / 2.0 / n;
      final catIdx = (normY * n).floor().clamp(0, n - 1);
      final catNormCenter = (catIdx + 0.5) / n;
      if ((normY - catNormCenter).abs() > halfBandNorm) return [];
      final category = categories[catIdx];

      // After data-swap: row['x'] = category (String), row['y'] = value (num).
      final activeData = _filteredData.isNotEmpty ? _filteredData : data;
      Map<String, dynamic>? hitRow;
      for (final row in activeData) {
        if (row['x'] != category) continue;
        final yVal = row['y'];
        if (yVal is! num) continue;
        final barValue = yVal.toDouble();
        final valueLow = barValue >= 0 ? 0.0 : barValue;
        final valueHigh = barValue >= 0 ? barValue : 0.0;
        // If bar_width is set, use it to constrain the category hit area.
        if (row.containsKey('bar_width')) {
          final w = (row['bar_width'] as num).toDouble();
          final halfW = (w / 2) / n;
          if ((normY - catNormCenter).abs() > halfW) continue;
        }
        if (cursorDataValue >= valueLow && cursorDataValue <= valueHigh) {
          hitRow = row;
          break;
        }
      }
      if (hitRow == null) return [];
      return _buildTooltipElements(size, hitRow, anchor);
    }

    if (selectedTuples.isEmpty) return [];

    // For stacked/grouped bar charts, multiple tuples share the same x column.
    // Pick the bar segment actually under the cursor.
    g.Tuple tuple;
    if (widget.layout.barMode == BarMode.stack && selectedTuples.length > 1) {
      // Map cursor y → data y using chart padding + domain.
      const topPad = 5.0;
      const bottomPad = 40.0;
      final innerHeight = size.height - topPad - bottomPad;
      final cursorInnerY = _hoverLocalPosition.dy - topPad;
      final normalizedY = 1.0 - cursorInnerY / innerHeight;
      final cursorDataY =
          _domainY.$1 + normalizedY * (_domainY.$2 - _domainY.$1);

      // Build stacked ranges in trace order and find which one contains cursor.
      final xVal = selectedTuples.values.first['x'];
      double cumulativeBottom = 0.0;
      g.Tuple? hit;
      for (final trace in widget.traces.whereType<BarTrace>()) {
        if (trace.visible == TraceVisibility.off) continue;
        final idx = trace.x.indexWhere((v) => v == xVal);
        if (idx < 0) continue;
        final barY = (trace.y[idx] as num).toDouble();
        final top = cumulativeBottom + barY;
        final matchedEntry = selectedTuples.entries.firstWhere(
          (e) => e.value['name'] == (trace.name ?? ''),
          orElse: () => selectedTuples.entries.first,
        );
        hit = matchedEntry.value;
        if (cursorDataY >= cumulativeBottom && cursorDataY <= top) break;
        cumulativeBottom = top;
      }
      tuple = hit ?? selectedTuples.values.first;
    } else if (widget.layout.barMode == BarMode.group &&
        selectedTuples.length > 1) {
      // Compute expected canvas-x for each trace's dodged bar and pick
      // the one whose center is closest to the cursor x.
      final barTraces = widget.traces.whereType<BarTrace>().toList();
      final nGroups = barTraces.length;
      final barGap = widget.layout.barGap.toDouble();
      final categories = <Object>[];
      for (final trace in barTraces) {
        for (final xv in trace.x) {
          if (!categories.contains(xv)) categories.add(xv);
        }
      }
      final nCategories = categories.length;
      final xVal = selectedTuples.values.first['x'];
      final c = categories.indexOf(xVal);

      if (c >= 0 && nCategories > 0 && nGroups > 0) {
        const leftPad = 40.0;
        const rightPad = 10.0;
        final plotWidth = size.width - leftPad - rightPad;
        final band = 1.0 / nCategories;
        const align = 0.5; // DiscreteScale default
        final ratio = (1 - barGap) / nGroups; // DodgeModifier ratio
        final bias = ratio * band;
        final accumulatedStart = -bias * (nGroups - 1) / 2.0; // symmetric
        final catNormX = (c + align) * band;

        g.Tuple? best;
        double bestDist = double.infinity;
        for (var b = 0; b < nGroups; b++) {
          final trace = barTraces[b];
          final barNormX = catNormX + accumulatedStart + b * bias;
          final barCanvasX = leftPad + barNormX * plotWidth;
          final dist = (_hoverLocalPosition.dx - barCanvasX).abs();
          if (dist < bestDist) {
            bestDist = dist;
            best = selectedTuples.values.firstWhere(
              (t) => t['name'] == (trace.name ?? ''),
              orElse: () => selectedTuples.values.first,
            );
          }
        }
        tuple = best ?? selectedTuples.values.first;
      } else {
        tuple = selectedTuples.values.first;
      }
    } else if (widget.traces.any((t) => t is BarTrace) &&
        widget.traces.any((t) => t is ScatterTrace)) {
      // Mixed bar+scatter chart: hit-test each type independently and show
      // the tooltip only for the element the cursor is actually over/near.
      g.Tuple? barHit;
      g.Tuple? scatterHit;
      for (final t in selectedTuples.values) {
        final n = t['name'] as String;
        final isBar = widget.traces.whereType<BarTrace>().any(
          (tr) => (tr.name ?? '') == n,
        );
        if (isBar) {
          if (barHit == null && _isCursorOverBar(n, t['x'] as Object, size)) {
            barHit = t;
          }
        } else {
          if (scatterHit == null &&
              _isCursorNearScatterPoint(t['x'], t['y'], size)) {
            scatterHit = t;
          }
        }
      }
      if (barHit != null) {
        tuple = barHit;
      } else if (scatterHit != null) {
        tuple = scatterHit;
      } else {
        return [];
      }
    } else {
      tuple = selectedTuples.values.first;
    }

    final name = tuple['name'] as String;

    // For pure-bar (non-mixed) charts: hide tooltip when cursor is not over a bar.
    final isBarTuple = widget.traces.whereType<BarTrace>().any(
      (t) => (t.name ?? '') == name,
    );
    if (isBarTuple &&
        !widget.traces.any((t) => t is ScatterTrace) &&
        !_isCursorOverBar(name, tuple['x'] as Object, size)) {
      return [];
    }

    return _buildTooltipElements(size, tuple, anchor);
  }

  /// Builds the tooltip [g.MarkElement]s for a given data row / tuple.
  List<g.MarkElement> _buildTooltipElements(
    Size size,
    Map<String, dynamic> tuple,
    Offset anchor,
  ) {
    final name = tuple['name'] as String;
    Color traceColor = const Color(0xff595959);
    for (var i = 0; i < widget.traces.length; i++) {
      final trace = widget.traces[i];
      if (trace.name == name) {
        traceColor = Defaults.colors[i];
        break;
      }
    }

    final xVal = tuple['x'];
    final yVal = tuple['y'];
    final pointText = tuple['text'] as String? ?? '';
    final xStr = xVal is DateTime ? xVal.toIso8601String() : xVal.toString();
    final text = pointText.isNotEmpty
        ? '($xStr, $yVal) $name\n$pointText'
        : '($xStr, $yVal) $name';

    final textStyle = TextStyle(
      color: traceColor,
      // fontSize: 12,
    );
    const padding = EdgeInsets.all(5.0);

    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    painter.layout();

    final w = padding.left + painter.width + padding.right;
    final h = padding.top + painter.height + padding.bottom;

    // For stacked/grouped bars, anchor the tooltip at the cursor so it
    // follows the mouse rather than jumping to the bar-top position.
    final tipOrigin =
        (widget.layout.barMode == BarMode.stack ||
            widget.layout.barMode == BarMode.group)
        ? _hoverLocalPosition
        : anchor;
    var rect = Rect.fromLTWH(tipOrigin.dx + 10, tipOrigin.dy - h / 2, w, h);
    final hAdj = rect.left < 0
        ? -rect.left
        : (rect.right > size.width ? size.width - rect.right : 0.0);
    final vAdj = rect.top < 0
        ? -rect.top
        : (rect.bottom > size.height ? size.height - rect.bottom : 0.0);
    rect = rect.translate(hAdj, vAdj);
    final textPaintPoint = rect.topLeft + padding.topLeft;

    return [
      g.RectElement(
        rect: rect,
        borderRadius: const BorderRadius.all(Radius.circular(3)),
        style: g.PaintStyle(fillColor: const Color(0xf0ffffff), elevation: 3),
      ),
      g.LabelElement(
        text: text,
        anchor: textPaintPoint,
        style: g.LabelStyle(textStyle: textStyle, align: Alignment.bottomRight),
      ),
    ];
  }

  /// Returns the [g.BasicLineShape] corresponding to the [LineShape] and [Dash]
  /// of the trace with the given [name].
  g.LineShape _lineShapeFor(String name, List<Trace> traces) {
    for (var i = 0; i < traces.length; i++) {
      final trace = traces[i];
      if (trace is! ScatterTrace) continue;
      if (trace.name == name && trace.mode.toString().contains('lines')) {
        final ls = trace.line?.shape ?? LineShape.linear;
        final dash = trace.line?.dash.dashPattern(
          trace.line?.dash ?? Dash.solid,
        );
        return switch (ls) {
          LineShape.spline => g.BasicLineShape(smooth: true, dash: dash),
          LineShape.hv => g.BasicLineShape(stepped: true, dash: dash),
          LineShape.vh => LineShapeVh(dash: dash),
          _ => g.BasicLineShape(dash: dash),
        };
      }
    }
    return g.BasicLineShape();
  }

  List<g.Mark<g.Shape>> makeMarks(
    List<Trace> traces, {
    double? chartWidth,
    double? chartHeight,
  }) {
    return [
      ..._makeScatterMarks(traces.whereType<ScatterTrace>().toList()),
      _makeIntervalMark(
        traces.whereType<BarTrace>().toList(),
        barMode: widget.layout.barMode,
        barGap: widget.layout.barGap.toDouble(),
        barGroupGap: widget.layout.barGroupGap.toDouble(),
        chartWidth: chartWidth,
        chartHeight: chartHeight,
        domainX: _domainX,
        hasIndividualWidths: _hasBarWidths,
        isHorizontal: _hasHorizontalBars,
      ),
    ];
  }

  /// Marks for [ScatterTrace] entries: AreaMark + LineMark + PointMark.
  List<g.Mark<g.Shape>> _makeScatterMarks(List<ScatterTrace> traces) {
    return [
      // Area fills are drawn first so they appear below lines and markers.
      if (_hasFill)
        g.AreaMark(
          position:
              g.Varset('x') *
              (g.Varset('y_fill') + g.Varset('y')) /
              g.Varset('name'),
          color: g.ColorEncode(
            encoder: (e) {
              for (var i = 0; i < traces.length; i++) {
                final trace = traces[i];
                if (trace.name != e['name']) continue;
                if (trace.visible == TraceVisibility.off) {
                  return Colors.transparent;
                }
                if (trace.fill == Fill.none) return Colors.transparent;
                if (trace.fillColor != null) return trace.fillColor!;
                // Default: trace line/marker color at 50% opacity.
                final lineColor = trace.line?.color;
                final mc = trace.marker?.first.color;
                final globalIdx = widget.traces.indexOf(trace);
                Color base = Defaults.colors[globalIdx < 0 ? i : globalIdx];
                if (lineColor is Color && lineColor != Colors.transparent) {
                  base = lineColor;
                } else if (mc is Color && mc != Colors.transparent) {
                  base = mc;
                }
                return base.withValues(alpha: 0.5);
              }
              return Colors.transparent;
            },
          ),
          shape: g.ShapeEncode<g.AreaShape>(
            encoder: (e) {
              for (var i = 0; i < traces.length; i++) {
                final trace = traces[i];
                if (trace.name != e['name']) continue;
                final ls = trace.line?.shape ?? LineShape.linear;
                return switch (trace.fill) {
                  Fill.toSelf => g.BasicAreaShape(loop: true),
                  _ => g.BasicAreaShape(
                    smooth: ls == LineShape.spline,
                    stepped: ls == LineShape.hv || ls == LineShape.vh,
                  ),
                };
              }
              return g.BasicAreaShape();
            },
          ),
        ),
      g.LineMark(
        position: g.Varset('x') * g.Varset('y') / g.Varset('name'),
        shape: g.ShapeEncode(
          encoder: (e) => _lineShapeFor(e['name'] as String, traces),
        ),
        size: g.SizeEncode(
          encoder: (e) {
            for (var i = 0; i < traces.length; i++) {
              final trace = traces[i];
              if (trace.name == e['name']) {
                return (trace.line?.width ?? 2.0).toDouble();
              }
            }
            return 2.0;
          },
        ),
        color: g.ColorEncode(
          encoder: (e) {
            for (var i = 0; i < traces.length; i++) {
              final trace = traces[i];
              if (trace.visible == TraceVisibility.off) continue;
              if (trace.name == e['name']) {
                if (trace.mode.toString().contains('lines')) {
                  final lineColor = trace.line?.color;
                  if (lineColor != null && lineColor != Colors.transparent) {
                    return lineColor;
                  }
                  final globalIdx = widget.traces.indexOf(trace);
                  return Defaults.colors[globalIdx < 0 ? i : globalIdx];
                }
              }
            }
            return Colors.transparent;
          },
        ),
      ),
      g.PointMark(
        color: g.ColorEncode(
          encoder: (e) {
            for (var i = 0; i < traces.length; i++) {
              final trace = traces[i];
              if (trace.visible == TraceVisibility.off) continue;
              if (trace.name == e['name']) {
                if (trace.mode.toString().contains('markers')) {
                  final mc = trace.marker?.first.color;
                  if (mc is Color && mc != Colors.transparent) return mc;
                  final globalIdx = widget.traces.indexOf(trace);
                  return Defaults.colors[globalIdx < 0 ? i : globalIdx];
                }
              }
            }
            return Colors.transparent;
          },
        ),
        size: g.SizeEncode(
          encoder: (e) {
            for (var i = 0; i < traces.length; i++) {
              final trace = traces[i];
              if (trace.visible == TraceVisibility.off) continue;
              if (trace.name == e['name']) {
                if (trace.mode.toString().contains('markers')) {
                  return e['marker.size'] as double;
                }
              }
            }
            return 0.0;
          },
        ),
      ),
    ];
  }

  /// Mark for [BarTrace] entries: IntervalMark with optional dodge/stack.
  g.IntervalMark _makeIntervalMark(
    List<BarTrace> traces, {
    BarMode? barMode,
    double barGap = 0.2,
    double barGroupGap = 0,
    double? chartWidth,
    double? chartHeight,
    (num, num)? domainX,
    bool hasIndividualWidths = false,
    bool isHorizontal = false,
  }) {
    // For horizontal bars the category dimension is y; for vertical it is x.
    final nCategories = traces.isEmpty
        ? 1
        : (isHorizontal
              ? traces.expand((t) => t.y).toSet().length
              : traces.expand((t) => t.x).toSet().length);
    final nGroups = traces.isEmpty ? 1 : traces.length;

    // DodgeModifier.ratio is the step between bars as a fraction of the band.
    // Using (1 - barGap) / nGroups leaves barGap as inter-group whitespace.
    final List<g.Modifier> modifiers = switch (barMode) {
      BarMode.group => [g.DodgeModifier(ratio: (1 - barGap) / nGroups)],
      BarMode.stack => [g.StackModifier()],
      _ => [],
    };

    // Position varset: both horizontal and vertical bars use Varset('x') * Varset('y').
    // For horizontal bars, x holds categories (String) and y holds values (num),
    // so that the LineMark's firstVariables = ['x','y'] drives the axis labels
    // correctly: with transposed coord, 'x' (categories) → LEFT axis, 'y' (values)
    // → BOTTOM axis.
    final positionEncode = g.Varset('x') * g.Varset('y') / g.Varset('name');

    // Color encoder shared by all branches below.
    final colorEncode = g.ColorEncode(
      encoder: (e) {
        for (var i = 0; i < traces.length; i++) {
          final trace = traces[i];
          if (trace.visible == TraceVisibility.off) continue;
          if (trace.name == e['name']) {
            final mc = trace.marker?.isNotEmpty == true
                ? trace.marker!.first.color
                : null;
            if (mc is Color && mc != Colors.transparent) return mc;
            final globalIdx = widget.traces.indexOf(trace);
            return Defaults.colors[globalIdx < 0 ? i : globalIdx];
          }
        }
        return Colors.transparent;
      },
    );

    // When individual widths are set, use a per-point SizeEncode that converts
    // bar_width from data units to pixels.
    if (hasIndividualWidths) {
      if (isHorizontal) {
        // bar_width is in category units (1.0 = one full category band).
        // If y values are numeric, bar_width is in y-axis data units.
        final plotH = chartHeight ?? 300.0;
        final sampleY = traces.isEmpty ? null : traces.first.y.firstOrNull;
        g.SizeEncode sizeEncode;
        if (sampleY is num) {
          final yRange = (_domainY.$2 - _domainY.$1).toDouble();
          sizeEncode = g.SizeEncode(
            encoder: (e) {
              final w = e['bar_width'];
              if (w == null || yRange <= 0) return 10.0;
              return (w as num).toDouble() / yRange * plotH;
            },
          );
        } else {
          // Categorical y: one category band = plotH / nCategories pixels.
          sizeEncode = g.SizeEncode(
            encoder: (e) {
              final w = e['bar_width'];
              if (w == null || nCategories <= 0) return 10.0;
              return (w as num).toDouble() / nCategories * plotH;
            },
          );
        }
        return g.IntervalMark(
          position: positionEncode,
          modifiers: modifiers.isEmpty ? null : modifiers,
          size: sizeEncode,
          color: colorEncode,
        );
      } else {
        final xRange = domainX != null
            ? (domainX.$2 - domainX.$1).toDouble()
            : 1.0;
        final plotW = chartWidth ?? 300.0;
        return g.IntervalMark(
          position: positionEncode,
          modifiers: modifiers.isEmpty ? null : modifiers,
          size: g.SizeEncode(
            encoder: (e) {
              final w = e['bar_width'];
              if (w == null || xRange <= 0) return 10.0;
              return (w as num).toDouble() / xRange * plotW;
            },
          ),
          color: colorEncode,
        );
      }
    }

    // Compute bar pixel size from layout gaps and available space.
    double? barSize;
    if (isHorizontal) {
      if (chartHeight != null && nCategories > 0) {
        if (barMode == BarMode.group && nGroups > 0) {
          barSize =
              (1 - barGroupGap) *
              (1 - barGap) *
              chartHeight /
              (nCategories * nGroups);
        } else {
          barSize = (1 - barGap) * chartHeight / nCategories;
        }
      }
    } else {
      if (chartWidth != null && nCategories > 0) {
        if (barMode == BarMode.group && nGroups > 0) {
          barSize =
              (1 - barGroupGap) *
              (1 - barGap) *
              chartWidth /
              (nCategories * nGroups);
        } else {
          barSize = (1 - barGap) * chartWidth / nCategories;
        }
      }
    }

    return g.IntervalMark(
      position: positionEncode,
      modifiers: modifiers.isEmpty ? null : modifiers,
      size: barSize != null ? g.SizeEncode(value: barSize) : null,
      color: colorEncode,
    );
  }

  /// Marks for traces rendered on the secondary y-axis.
  ///
  /// Only [ScatterTrace]s are supported on the secondary axis (no bars).
  /// Color resolution uses [widget.traces] so that global trace-index colors
  /// are applied correctly even when only a subset of traces is passed.
  List<g.Mark<g.Shape>> _makeSecondaryMarks(List<ScatterTrace> traces) {
    return [
      g.LineMark(
        position: g.Varset('x') * g.Varset('y') / g.Varset('name'),
        shape: g.ShapeEncode(
          encoder: (e) => _lineShapeFor(e['name'] as String, traces),
        ),
        size: g.SizeEncode(
          encoder: (e) {
            for (final trace in traces) {
              if (trace.visible == TraceVisibility.off) continue;
              if (trace.name == e['name'] &&
                  trace.mode.toString().contains('lines')) {
                return trace.line?.width.toDouble() ?? 2.0;
              }
            }
            return 0.0;
          },
        ),
        color: g.ColorEncode(
          encoder: (e) {
            for (var i = 0; i < widget.traces.length; i++) {
              final trace = widget.traces[i];
              if (trace.visible == TraceVisibility.off) continue;
              if (trace.name != e['name']) continue;
              if (trace is ScatterTrace &&
                  trace.mode.toString().contains('lines')) {
                final lineColor = trace.line?.color;
                if (lineColor is Color && lineColor != Colors.transparent) {
                  return lineColor;
                }
              }
              return Defaults.colors[i];
            }
            return Colors.transparent;
          },
        ),
      ),
      g.PointMark(
        color: g.ColorEncode(
          encoder: (e) {
            for (var i = 0; i < widget.traces.length; i++) {
              final trace = widget.traces[i];
              if (trace.visible == TraceVisibility.off) continue;
              if (trace.name != e['name']) continue;
              if (trace is ScatterTrace &&
                  trace.mode.toString().contains('markers')) {
                final mc = trace.marker?.first.color;
                if (mc is Color && mc != Colors.transparent) return mc;
                return Defaults.colors[i];
              }
            }
            return Colors.transparent;
          },
        ),
        size: g.SizeEncode(
          encoder: (e) {
            for (final trace in traces) {
              if (trace.visible == TraceVisibility.off) continue;
              if (trace.name == e['name'] &&
                  trace.mode.toString().contains('markers')) {
                return e['marker.size'] as double;
              }
            }
            return 0.0;
          },
        ),
      ),
    ];
  }

  /// True when the chart uses a grid or has traces assigned to non-primary
  /// x-axes (i.e. 'x2', 'x3', …).  In this mode each unique (xAxis, yAxis)
  /// pair is rendered as an independent [g.Chart] positioned inside a [Stack].
  bool get _isSubplotMode =>
      widget.layout.grid != null || widget.traces.any((t) => t.xAxis != 'x');

  /// Builds the list of subplot specs from the layout grid (when present) or
  /// from the axis domain properties on the layout axes.
  List<_SubplotSpec> _computeSubplotSpecs() {
    final grid = widget.layout.grid;
    final xDomains = <String, (num, num)>{};
    final yDomains = <String, (num, num)>{};

    if (grid != null) {
      final cols = grid.columns;
      final rows = grid.rows;
      // Gap width / height as a fraction of the TOTAL chart dimension.
      // xGap is defined as "fraction of the total width available to one cell",
      // so gap between adjacent cells = xGap * (1/cols).
      final gapW = cols > 1 ? grid.xGap.toDouble() / cols : 0.0;
      final gapH = rows > 1 ? grid.yGap.toDouble() / rows : 0.0;
      // Width / height of each cell's plot area.
      final cellW = (1.0 - (cols - 1) * gapW) / cols;
      final cellH = (1.0 - (rows - 1) * gapH) / rows;
      final stepX = cellW + gapW;
      final stepY = cellH + gapH;

      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          String xAxisId, yAxisId;
          if (grid.pattern == GridPattern.independent) {
            // Each cell gets its own xy pair assigned in row-major order
            // (left→right across the topmost row first).
            final cellIndex = r * cols + c;
            xAxisId = cellIndex == 0 ? 'x' : 'x${cellIndex + 1}';
            yAxisId = cellIndex == 0 ? 'y' : 'y${cellIndex + 1}';
          } else {
            // coupled: one x-axis per column, one y-axis per row.
            xAxisId = c == 0 ? 'x' : 'x${c + 1}';
            yAxisId = r == 0 ? 'y' : 'y${r + 1}';
          }

          // X domain: straightforward left→right column layout.
          xDomains[xAxisId] = (c * stepX, c * stepX + cellW);

          // Y domain: for topToBottom the first row (r=0) is at the top, which
          // maps to the highest y values (1 = top in plot coords).
          final rVisual = (grid.rowOrder == GridRowOrder.topToBottom)
              ? rows - 1 - r
              : r;
          yDomains[yAxisId] = (rVisual * stepY, rVisual * stepY + cellH);
        }
      }
    } else {
      // Manual subplot positioning: read domains from the layout axis objects.
      XAxis? xAxisFor(String id) => switch (id) {
        'x' || 'x1' => widget.layout.xAxis,
        'x2' => widget.layout.xAxis2,
        'x3' => widget.layout.xAxis3,
        'x4' => widget.layout.xAxis4,
        _ => null,
      };
      YAxis? yAxisFor(String id) => switch (id) {
        'y' || 'y1' => widget.layout.yAxis,
        'y2' => widget.layout.yAxis2,
        'y3' => widget.layout.yAxis3,
        'y4' => widget.layout.yAxis4,
        _ => null,
      };

      for (final trace in widget.traces) {
        xDomains.putIfAbsent(
          trace.xAxis,
          () => xAxisFor(trace.xAxis)?.domain ?? (0.0, 1.0),
        );
        yDomains.putIfAbsent(
          trace.yAxis,
          () => yAxisFor(trace.yAxis)?.domain ?? (0.0, 1.0),
        );
      }
    }

    // Group traces by (xAxisId, yAxisId) pair.
    final groups = <(String, String), List<Trace>>{};
    for (final trace in widget.traces) {
      groups.putIfAbsent((trace.xAxis, trace.yAxis), () => []).add(trace);
    }

    return [
      for (final entry in groups.entries)
        _SubplotSpec(
          xAxisId: entry.key.$1,
          yAxisId: entry.key.$2,
          xDomain: xDomains[entry.key.$1] ?? (0.0, 1.0),
          yDomain: yDomains[entry.key.$2] ?? (0.0, 1.0),
          traces: entry.value,
        ),
    ];
  }

  /// Computes the required left padding to accommodate the widest tick label.
  /// For horizontal bar charts the category labels appear on the left axis;
  /// measuring them with [TextPainter] avoids labels being clipped.
  double _computeLeftPad() {
    if (!_hasHorizontalBars) return 40.0;
    final categories = <String>{};
    for (final trace in widget.traces.whereType<BarTrace>()) {
      for (final yv in trace.y) {
        categories.add(yv.toString());
      }
    }
    if (categories.isEmpty) return 40.0;
    final textStyle = Defaults.textStyle.copyWith(color: Colors.black);
    double maxWidth = 0;
    for (final label in categories) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      if (painter.width > maxWidth) maxWidth = painter.width;
    }
    // 7.5 px label offset + 8 px gap between label and plot edge
    return maxWidth + 15.5;
  }

  /// Builds a single subplot panel positioned inside a [Stack] of size
  /// [totalW] × [totalH].  Temporarily swaps the relevant instance fields so
  /// existing helpers ([makeMarks], [makeVariables], [_computeLeftPad]) all use
  /// the per-subplot data, then restores them before returning.
  /// Builds a per-subplot tooltip renderer that closes over the panel's own
  /// data, domain, and traces so it doesn't read from the shared instance fields.
  g.TooltipRenderer _makeSubplotTooltipRenderer({
    required List<Map<String, dynamic>> panelData,
    required (num, num) panelDomainX,
    required (num, num) panelDomainY,
    required bool panelHasBarWidths,
    required bool panelHasHorizontalBars,
    required List<Trace> panelTraces,
    required String panelKey,
    required double leftPad,
    required double bottomPad,
    required double topPad,
    required double rightPad,
  }) {
    return (Size size, Offset anchor, Map<int, g.Tuple> selectedTuples) {
      final hoverPos = _subplotHoverPositions[panelKey] ?? Offset.zero;

      // ── Custom bar hit-testing (per-point widths) ────────────────────────
      if (panelHasBarWidths && !panelHasHorizontalBars) {
        final plotW = size.width - leftPad - rightPad;
        final plotH = size.height - topPad - bottomPad;
        final xRange = (panelDomainX.$2 - panelDomainX.$1).toDouble();
        final yRange = (panelDomainY.$2 - panelDomainY.$1).toDouble();
        final cursorDataX =
            panelDomainX.$1 + ((hoverPos.dx - leftPad) / plotW) * xRange;
        final cursorDataY =
            panelDomainY.$1 + ((1.0 - (hoverPos.dy - topPad) / plotH)) * yRange;
        Map<String, dynamic>? hitRow;
        for (final row in panelData) {
          if (!row.containsKey('bar_width')) continue;
          final xVal = row['x'];
          if (xVal is! num) continue;
          final w = (row['bar_width'] as num).toDouble();
          if (cursorDataX < xVal - w / 2 || cursorDataX > xVal + w / 2) {
            continue;
          }
          final yVal = (row['y'] as num).toDouble();
          final yBottom = yVal < 0 ? yVal : 0.0;
          final yTop = yVal < 0 ? 0.0 : yVal;
          if (cursorDataY < yBottom || cursorDataY > yTop) continue;
          hitRow = row;
          break;
        }
        if (hitRow == null) return [];
        return _buildTooltipElements(size, hitRow, anchor);
      }

      // ── Horizontal bar hit-testing ────────────────────────────────────────
      if (panelHasHorizontalBars) {
        final plotW = size.width - leftPad - rightPad;
        final plotH = size.height - topPad - bottomPad;
        final yRange = (panelDomainY.$2 - panelDomainY.$1).toDouble();
        final cursorDataValue =
            panelDomainY.$1 + ((hoverPos.dx - leftPad) / plotW) * yRange;
        final normScreenY = (hoverPos.dy - topPad).clamp(0.0, plotH) / plotH;
        final normY = 1.0 - normScreenY;
        final barTraces = panelTraces.whereType<BarTrace>().toList();
        final categories = <Object>[];
        for (final t in barTraces) {
          for (final yv in t.y) {
            if (!categories.contains(yv)) categories.add(yv);
          }
        }
        final n = categories.length;
        if (n == 0) return [];
        final barGap = widget.layout.barGap.toDouble();
        final halfBandNorm = (1 - barGap) / 2.0 / n;
        final catIdx = (normY * n).floor().clamp(0, n - 1);
        final catNormCenter = (catIdx + 0.5) / n;
        if ((normY - catNormCenter).abs() > halfBandNorm) return [];
        final category = categories[catIdx];
        Map<String, dynamic>? hitRow;
        for (final row in panelData) {
          if (row['x'] != category) continue;
          final yVal = row['y'];
          if (yVal is! num) continue;
          final barValue = yVal.toDouble();
          final valueLow = barValue >= 0 ? 0.0 : barValue;
          final valueHigh = barValue >= 0 ? barValue : 0.0;
          if (row.containsKey('bar_width')) {
            final w = (row['bar_width'] as num).toDouble();
            final halfW = (w / 2) / n;
            if ((normY - catNormCenter).abs() > halfW) continue;
          }
          if (cursorDataValue >= valueLow && cursorDataValue <= valueHigh) {
            hitRow = row;
            break;
          }
        }
        if (hitRow == null) return [];
        return _buildTooltipElements(size, hitRow, anchor);
      }

      // ── Standard scatter/bar selection ───────────────────────────────────
      if (selectedTuples.isEmpty) return [];
      final tuple = selectedTuples.values.first;
      return _buildTooltipElements(size, tuple, anchor);
    };
  }

  Widget _buildSubplotPanel(
    _SubplotSpec spec,
    double totalW,
    double totalH,
    String visibilityKey,
  ) {
    // Pixel insets from each edge of the full chart area.
    // xDomain / yDomain are in normalized coords: 0 = left/bottom, 1 = right/top.
    // Flutter's Positioned uses insets from the top/bottom edges.
    final left = spec.xDomain.$1.toDouble() * totalW;
    final right = (1.0 - spec.xDomain.$2.toDouble()) * totalW;
    final top = (1.0 - spec.yDomain.$2.toDouble()) * totalH;
    final bottom = spec.yDomain.$1.toDouble() * totalH;

    final subW = totalW - left - right;
    final subH = totalH - top - bottom;

    // ── Save / override instance state ─────────────────────────────────────
    final savedDomainX = _domainX;
    final savedDomainY = _domainY;
    final savedData = data;
    final savedHasFill = _hasFill;
    final savedHasBarWidths = _hasBarWidths;
    final savedHasHorizontalBars = _hasHorizontalBars;

    final result = buildChartData(spec.traces, layout: widget.layout);
    _domainX = result.domainX;
    _domainY = result.domainY;
    _hasFill = result.hasFill;
    _hasBarWidths = result.hasBarWidths;
    _hasHorizontalBars = result.hasHorizontalBars;
    data = result.data;

    // ── Padding / sizing for this panel ────────────────────────────────────
    final subLeftPad = _computeLeftPad();
    const subTopPad = 5.0;
    const subBottomPad = 40.0;
    const subRightPad = 10.0;
    final usableW = subW - subLeftPad - subRightPad;
    final usableH = subH - subTopPad - subBottomPad;

    // ── Variables & marks ──────────────────────────────────────────────────
    final variables = buildChartVariables(
      data,
      domainX: _domainX,
      domainY: _domainY,
      includeYFill: _hasFill,
      includeBarRange: _hasBarWidths,
    );
    final marks = makeMarks(
      spec.traces,
      chartWidth: usableW,
      chartHeight: usableH,
    );

    final subKey = '${spec.xAxisId}_${spec.yAxisId}_$visibilityKey';

    // ── Per-panel gesture stream and hover tracking ────────────────────────
    final panelKey = '${spec.xAxisId}_${spec.yAxisId}';
    final panelCtrl = _subplotGestureControllers.putIfAbsent(panelKey, () {
      final ctrl = StreamController<g.GestureEvent>.broadcast();
      ctrl.stream.listen((event) {
        if (event.gesture.type == g.GestureType.hover) {
          _subplotHoverPositions[panelKey] = event.gesture.localPosition;
        }
      });
      return ctrl;
    });

    // Capture panel state for the tooltip renderer before restoration.
    final panelData = List<Map<String, dynamic>>.from(data);
    final panelDomainX = _domainX;
    final panelDomainY = _domainY;
    final panelHasBarWidths = _hasBarWidths;
    final panelHasHorizontalBars = _hasHorizontalBars;

    final tooltipRenderer = _makeSubplotTooltipRenderer(
      panelData: panelData,
      panelDomainX: panelDomainX,
      panelDomainY: panelDomainY,
      panelHasBarWidths: panelHasBarWidths,
      panelHasHorizontalBars: panelHasHorizontalBars,
      panelTraces: spec.traces,
      panelKey: panelKey,
      leftPad: subLeftPad,
      topPad: subTopPad,
      bottomPad: subBottomPad,
      rightPad: subRightPad,
    );

    final hasBarInPanel = spec.traces.any((t) => t is BarTrace);
    final isHoriz = _hasHorizontalBars;
    final chart = g.Chart(
      key: ValueKey(subKey),
      padding: (_) =>
          EdgeInsets.fromLTRB(subLeftPad, subTopPad, subRightPad, subBottomPad),
      data: data,
      variables: variables,
      marks: marks,
      coord: g.RectCoord(
        horizontalRange: [0, 1],
        verticalRange: [0, 1],
        transposed: isHoriz,
      ),
      axes: isHoriz
          ? [
              g.AxisGuide(
                grid: g.Defaults.strokeStyle,
                label: g.LabelStyle(
                  textStyle: Defaults.textStyle.copyWith(color: Colors.black),
                  offset: const Offset(-7.5, 0),
                ),
              ),
              g.AxisGuide(
                grid: g.Defaults.strokeStyle,
                label: g.LabelStyle(
                  textStyle: Defaults.textStyle.copyWith(color: Colors.black),
                  offset: const Offset(0, 7.5),
                ),
              ),
            ]
          : [
              g.AxisGuide(
                grid: g.Defaults.strokeStyle,
                label: g.LabelStyle(
                  textStyle: Defaults.textStyle.copyWith(color: Colors.black),
                  offset: const Offset(0, 7.5),
                ),
              ),
              g.AxisGuide(
                grid: g.Defaults.strokeStyle,
                label: g.LabelStyle(
                  textStyle: Defaults.textStyle.copyWith(color: Colors.black),
                  offset: const Offset(-7.5, 0),
                ),
              ),
            ],
      selections: {
        'tooltipMouse': hasBarInPanel
            ? g.PointSelection(
                on: {g.GestureType.hover},
                dim: g.Dim.x,
                nearest: true,
                variable: 'x',
                devices: {PointerDeviceKind.mouse},
              )
            : g.PointSelection(
                on: {g.GestureType.hover},
                nearest: false,
                testRadius: 15.0,
                devices: {PointerDeviceKind.mouse},
              ),
      },
      tooltip: g.TooltipGuide(renderer: tooltipRenderer),
      gestureStream: panelCtrl,
    );

    // ── Restore instance state ─────────────────────────────────────────────
    _domainX = savedDomainX;
    _domainY = savedDomainY;
    data = savedData;
    _hasFill = savedHasFill;
    _hasBarWidths = savedHasBarWidths;
    _hasHorizontalBars = savedHasHorizontalBars;

    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: chart,
    );
  }

  /// Builds the full subplot area (a [Stack] of positioned [g.Chart] widgets).
  Widget _buildSubplotArea(BoxConstraints constraints, String visibilityKey) {
    final totalW = constraints.maxWidth;
    final totalH = constraints.maxHeight;
    final specs = _computeSubplotSpecs();
    return Stack(
      children: [
        for (final spec in specs)
          _buildSubplotPanel(spec, totalW, totalH, visibilityKey),
      ],
    );
  }

  Widget chartArea({
    required double usableWidth,
    required double usableHeight,
    required double leftPad,
    required double rightPad,
    required String visibilityKey,
    required Map<String, g.Variable<Map<dynamic, dynamic>, dynamic>> variables,
  }) {
    return Container(
      key: _chartKey,
      child: Stack(
        children: [
          // if shapes are under the chart data
          if (widget.layout.shapes != null &&
              widget.layout.shapes!.any((s) => s.layer == ShapeLayer.below))
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: ShapesPainter(
                    shapes: widget.layout.shapes!
                        .where((s) => s.layer == ShapeLayer.below)
                        .toList(),
                    domainX: (_filteredDomainX ?? _domainX),
                    domainY: (_filteredDomainY ?? _domainY),
                  ),
                ),
              ),
            ),
          g.Chart(
            key: ValueKey(visibilityKey),
            padding: (_) => EdgeInsets.fromLTRB(leftPad, 5, rightPad, 40),
            data: _filteredData.isNotEmpty ? _filteredData : data,
            variables: variables,
            marks: makeMarks(
              widget.traces,
              chartWidth: usableWidth,
              chartHeight: usableHeight,
            ),
            coord: g.RectCoord(
              horizontalRange: [0, 1],
              verticalRange: [0, 1],
              transposed: _hasHorizontalBars,
            ),
            axes: _hasHorizontalBars
                ? [
                    // dim1 = y (categories) → appears on LEFT when transposed
                    g.AxisGuide(
                      grid: g.Defaults.strokeStyle,
                      label: g.LabelStyle(
                        textStyle: Defaults.textStyle.copyWith(
                          color: Colors.black,
                        ),
                        offset: const Offset(-7.5, 0),
                      ),
                    ),
                    // dim2 = x (values) → appears on BOTTOM when transposed
                    g.AxisGuide(
                      grid: g.Defaults.strokeStyle,
                      label: g.LabelStyle(
                        textStyle: Defaults.textStyle.copyWith(
                          color: Colors.black,
                        ),
                        offset: const Offset(0, 7.5),
                      ),
                    ),
                  ]
                : [
                    g.AxisGuide(
                      grid: g.Defaults.strokeStyle,
                      label: g.LabelStyle(
                        textStyle: Defaults.textStyle.copyWith(
                          color: Colors.black,
                        ),
                        offset: const Offset(0, 7.5),
                      ),
                    ),
                    g.AxisGuide(
                      grid: g.Defaults.strokeStyle,
                      label: g.LabelStyle(
                        textStyle: Defaults.textStyle.copyWith(
                          color: Colors.black,
                        ),
                        offset: const Offset(-7.5, 0),
                      ),
                    ),
                  ],
            selections: {
              'tooltipMouse': widget.traces.any((t) => t is BarTrace)
                  ? g.PointSelection(
                      on: {g.GestureType.hover},
                      dim: g.Dim.x,
                      nearest: true,
                      variable: 'x',
                      devices: {PointerDeviceKind.mouse},
                    )
                  : g.PointSelection(
                      on: {g.GestureType.hover},
                      nearest: false,
                      testRadius: 15.0,
                      devices: {PointerDeviceKind.mouse},
                    ),
            },
            tooltip: g.TooltipGuide(renderer: _tooltipRenderer),
            gestureStream: _gestureController,
          ),
          // Secondary y-axis chart overlay (transparent, right-side axis only).
          if (_hasSecondaryYAxis && _dataSecondary.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: g.Chart(
                  key: ValueKey('secondary_$visibilityKey'),
                  padding: (_) => EdgeInsets.fromLTRB(leftPad, 5, rightPad, 40),
                  data: _dataSecondary,
                  variables: makeVariablesSecondary(_dataSecondary),
                  marks: _makeSecondaryMarks(
                    widget.traces
                        .whereType<ScatterTrace>()
                        .where((t) => t.yAxis == 'y2')
                        .toList(),
                  ),
                  coord: g.RectCoord(
                    horizontalRange: [0, 1],
                    verticalRange: [0, 1],
                  ),
                  axes: [
                    // x-axis: invisible (primary chart draws the x-axis)
                    g.AxisGuide(dim: g.Dim.x),
                    // y-axis: right side, no grid
                    g.AxisGuide(
                      dim: g.Dim.y,
                      position: 1.0,
                      flip: true,
                      label: g.LabelStyle(
                        textStyle: Defaults.textStyle.copyWith(
                          color: widget.layout.yAxis2?.color ?? Colors.black,
                        ),
                        offset: const Offset(7.5, 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // shapes above the chart data
          if (widget.layout.shapes != null &&
              widget.layout.shapes!.any((s) => s.layer == ShapeLayer.above))
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: ShapesPainter(
                    shapes: widget.layout.shapes!
                        .where((s) => s.layer == ShapeLayer.above)
                        .toList(),
                    domainX: (_filteredDomainX ?? _domainX),
                    domainY: (_filteredDomainY ?? _domainY),
                  ),
                ),
              ),
            ),
          // annotations (text + optional arrows) on top of all chart content
          if (widget.layout.annotations != null &&
              widget.layout.annotations!.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: AnnotationsPainter(
                    annotations: widget.layout.annotations!,
                    domainX: (_filteredDomainX ?? _domainX),
                    domainY: (_filteredDomainY ?? _domainY),
                  ),
                ),
              ),
            ),
          // if there is a selection
          if (_currentSelectionNormalized != null)
            Positioned(
              left: leftPad + _currentSelectionNormalized![0] * usableWidth,
              top: 0,
              bottom: 0,
              width:
                  (_currentSelectionNormalized![1] -
                      _currentSelectionNormalized![0]) *
                  usableWidth,
              child: IgnorePointer(
                child: Container(color: Colors.grey.withAlpha(64)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibilityKey =
        '${widget.traces.map((t) => t.visible.toString()).join('-')}'
        '|$_filteredDomainX|$_filteredDomainY';
    final chartTitle = widget.layout.title?.text ?? '';
    final showLegend =
        widget.layout.showLegend &&
        (widget.layout.legend?.visible ?? true) &&
        widget.traces.where((t) => t.visible != TraceVisibility.off).length > 1;
    final legendSide = widget.layout.legend?.side ?? Side.right;
    final legendMainAxis =
        widget.layout.legend?.mainAxisAlignment ?? MainAxisAlignment.start;
    final legendCrossAxis =
        widget.layout.legend?.crossAxisAlignment ?? CrossAxisAlignment.start;
    final legendAtTop = showLegend && legendSide == Side.top;
    final legendAtBottom = showLegend && legendSide == Side.bottom;
    final legendAtRight = showLegend && legendSide == Side.right;

    // ── Subplot mode ────────────────────────────────────────────────────────
    // When the layout has a grid or traces are assigned to multiple x-axes,
    // render each (xAxis, yAxis) group as an independent g.Chart positioned
    // inside a Stack.
    if (_isSubplotMode) {
      // Initialise late / mutable fields so helpers don't throw before the
      // first _buildSubplotPanel() call sets them properly.
      data = [];
      _domainX = (0, 1);
      _domainY = (0, 1);
      _hasFill = false;
      _hasBarWidths = false;
      _hasHorizontalBars = false;
      _dataSecondary = [];
      _xIsDateTime = false;

      return Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (chartTitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                chartTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (legendAtTop)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: _buildLegend(
                horizontal: true,
                mainAxisAlignment: legendMainAxis,
                crossAxisAlignment: legendCrossAxis,
              ),
            ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) =>
                        _buildSubplotArea(constraints, visibilityKey),
                  ),
                ),
                if (legendAtRight)
                  IntrinsicWidth(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                      child: _buildLegend(
                        horizontal: false,
                        mainAxisAlignment: legendMainAxis,
                        crossAxisAlignment: legendCrossAxis,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (legendAtBottom)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: _buildLegend(
                horizontal: true,
                mainAxisAlignment: legendMainAxis,
                crossAxisAlignment: legendCrossAxis,
              ),
            ),
        ],
      );
    }

    // ── Single-chart (non-subplot) mode ─────────────────────────────────────
    data = makeData(widget.traces);
    final variables = makeVariables(
      data,
      domainX: _filteredDomainX,
      domainY: _filteredDomainY,
    );
    final xAxisTitle = widget.layout.xAxis?.title?.text ?? '';
    final yAxisTitle = widget.layout.yAxis?.title?.text ?? '';
    final yAxis2Title = widget.layout.yAxis2?.title?.text ?? '';
    final yAxis2Color =
        widget.layout.yAxis2?.title?.style?.color ?? Colors.black;
    // When a secondary y-axis is present, increase right padding so the
    // right-side axis labels have room and both charts stay aligned.
    final double chartRightPad = _hasSecondaryYAxis ? 40.0 : 10.0;
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Chart title
                    if (chartTitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          chartTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    // Legend at top (horizontal, side == top)
                    if (legendAtTop)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: _buildLegend(
                          horizontal: true,
                          mainAxisAlignment: legendMainAxis,
                          crossAxisAlignment: legendCrossAxis,
                        ),
                      ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Y axis title (rotated 90° counter-clockwise)
                          if (yAxisTitle.isNotEmpty)
                            RotatedBox(
                              quarterTurns: 3,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  yAxisTitle,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final leftPad = _computeLeftPad();
                                      const topPad = 5.0;
                                      const bottomPad = 40.0;
                                      final rightPad = chartRightPad;
                                      final usableWidth =
                                          constraints.maxWidth -
                                          leftPad -
                                          rightPad;
                                      final usableHeight =
                                          constraints.maxHeight -
                                          topPad -
                                          bottomPad;
                                      return chartArea(
                                        usableWidth: usableWidth,
                                        usableHeight: usableHeight,
                                        leftPad: leftPad,
                                        rightPad: rightPad,
                                        visibilityKey: visibilityKey,
                                        variables: variables,
                                      );
                                    },
                                  ),
                                ),
                                if (xAxisTitle.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      xAxisTitle,
                                      textAlign: TextAlign.center,
                                      // style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ), // Expanded(Column with chart + x-axis title)
                          // Secondary Y axis title (rotated 270° clockwise, on the right)
                          if (yAxis2Title.isNotEmpty)
                            RotatedBox(
                              quarterTurns: 3, // this matches Plotly style
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  yAxis2Title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: yAxis2Color),
                                ),
                              ),
                            ),
                          // Right-side legend (side == right)
                          if (legendAtRight)
                            IntrinsicWidth(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 8.0,
                                  top: 8.0,
                                ),
                                child: _buildLegend(
                                  horizontal: false,
                                  mainAxisAlignment: legendMainAxis,
                                  crossAxisAlignment: legendCrossAxis,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ), // Expanded(chart Row)
                    // Legend at bottom (horizontal, side == bottom)
                    if (legendAtBottom)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: _buildLegend(
                          horizontal: true,
                          mainAxisAlignment: legendMainAxis,
                          crossAxisAlignment: legendCrossAxis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ), // Expanded(outer Row)
      ],
    );
  }

  Widget _buildLegend({
    bool horizontal = false,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    final items = <Widget>[];
    for (var i = 0; i < widget.traces.length; i++) {
      final trace = widget.traces[i];
      if (!trace.showLegend) continue;
      final label = trace.name ?? 'trace $i';
      final isVisible = trace.visible == TraceVisibility.on;

      // Build the swatch widget based on trace type.
      final Widget swatch = switch (trace) {
        ScatterTrace s => _buildScatterSwatch(s, i, isVisible),
        BarTrace b => _buildBarSwatch(b, i, isVisible),
        _ => const SizedBox(width: 40, height: 14),
      };

      final item = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() {
            trace.visible = isVisible
                ? TraceVisibility.off
                : TraceVisibility.on;
          }),
          child: Padding(
            padding: horizontal
                ? const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0)
                : const EdgeInsets.symmetric(vertical: 3.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                swatch,
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    // fontSize: 12,
                    color: isVisible ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      items.add(item);
    }

    if (horizontal) {
      return SizedBox(
        width: double.infinity,
        child: Wrap(
          direction: Axis.horizontal,
          alignment: switch (mainAxisAlignment) {
            MainAxisAlignment.center => WrapAlignment.center,
            MainAxisAlignment.end => WrapAlignment.end,
            MainAxisAlignment.spaceBetween => WrapAlignment.spaceBetween,
            MainAxisAlignment.spaceAround => WrapAlignment.spaceAround,
            MainAxisAlignment.spaceEvenly => WrapAlignment.spaceEvenly,
            _ => WrapAlignment.start,
          },
          crossAxisAlignment: switch (crossAxisAlignment) {
            CrossAxisAlignment.center => WrapCrossAlignment.center,
            CrossAxisAlignment.end => WrapCrossAlignment.end,
            _ => WrapCrossAlignment.start,
          },
          spacing: 8.0,
          runSpacing: 2.0,
          children: items,
        ),
      );
    }
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      children: items,
    );
  }

  /// Legend swatch for a [ScatterTrace]: fill rectangle + line + marker dot.
  Widget _buildScatterSwatch(ScatterTrace trace, int i, bool isVisible) {
    final lineColor = trace.line?.color;
    final lineDrawColor = (lineColor != null && lineColor != Colors.transparent)
        ? lineColor
        : Defaults.colors[i];
    final markerColor0 = trace.marker?.first.color;
    final markerDrawColor =
        (markerColor0 is Color && markerColor0 != Colors.transparent)
        ? markerColor0
        : Defaults.colors[i];
    final lineSwatchColor = isVisible ? lineDrawColor : Colors.grey.shade400;
    final markerSwatchColor = isVisible
        ? markerDrawColor
        : Colors.grey.shade400;

    Color? fillSwatchColor;
    if (trace.fill != Fill.none) {
      if (trace.fillColor != null) {
        fillSwatchColor = trace.fillColor!;
      } else {
        final mc = trace.marker?.first.color;
        Color base = Defaults.colors[i];
        if (lineDrawColor != Colors.transparent) {
          base = lineDrawColor;
        } else if (mc is Color && mc != Colors.transparent) {
          base = mc;
        }
        fillSwatchColor = base.withValues(alpha: 0.5);
      }
      if (!isVisible) fillSwatchColor = fillSwatchColor.withValues(alpha: 0.3);
    }

    return SizedBox(
      width: 40,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (fillSwatchColor != null)
            Container(
              width: 40,
              height: 14,
              decoration: BoxDecoration(
                color: fillSwatchColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          if (trace.mode.toString().contains('lines'))
            CustomPaint(
              size: const Size(40, 2),
              painter: _LegendLinePainter(
                color: lineSwatchColor,
                strokeWidth: (trace.line?.width ?? 2.0).toDouble(),
                dash: trace.line?.dash.dashPattern(
                  trace.line?.dash ?? Dash.solid,
                ),
              ),
            ),
          if (trace.mode.toString().contains('markers'))
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: markerSwatchColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  /// Legend swatch for a [BarTrace]: solid colored rectangle.
  Widget _buildBarSwatch(BarTrace trace, int i, bool isVisible) {
    final mc = trace.marker?.isNotEmpty == true
        ? trace.marker!.first.color
        : null;
    Color barColor = Defaults.colors[i];
    if (mc is Color && mc != Colors.transparent) barColor = mc;
    final swatchColor = isVisible ? barColor : Colors.grey.shade400;
    return Container(
      width: 40,
      height: 14,
      decoration: BoxDecoration(
        color: swatchColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
