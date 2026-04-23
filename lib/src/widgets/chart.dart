import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:graphic_lite/graphic_lite.dart';
import 'package:graphic/graphic.dart' as g;
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

class Chart extends StatefulWidget {
  Chart({super.key, required this.traces, Layout? layout})
    : layout = layout ?? Layout.getDefault();

  final List<ScatterTrace> traces;
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

  (num, num)? _filteredDomainX;
  (num, num)? _filteredDomainY;

  final StreamController<g.GestureEvent> _gestureController =
      StreamController<g.GestureEvent>.broadcast();
  StreamSubscription<g.GestureEvent>? _gestureSub;
  Offset? _dragStart;
  List<Map<String, dynamic>> _filteredData = [];
  List<double>? _currentSelectionNormalized;

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
    super.dispose();
  }

  /// Use the input [traces] to construct the data in the format that package
  /// `graphic` expects.
  ///
  /// Whether the x-axis uses DateTime values (affects domain/filter logic).
  bool _xIsDateTime = false;

  late (num, num) _domainX;
  late (num, num) _domainY;

  (num, num) _computeYDomainFromData(List<Map<String, dynamic>> pts) {
    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    for (final e in pts) {
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
  List<Map<String, dynamic>> makeData(List<ScatterTrace> traces) {
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
        data.add({
          'x': trace.x[j],
          'y': trace.y[j],
          'name': trace.name ?? 'trace $i',
          if (trace.text != null)
            'text': trace.text!.length == 1
                ? trace.text!.first
                : trace.text![j],
          if (trace.marker != null)
            'marker': trace.marker!.length == 1
                ? trace.marker!.first
                : trace.marker![j],
        });
      }
    }
    // Match graphic's 10% margin on each side of the data range — the same
    // formula used by LinearScale and TimeScale internally.
    if (minDt != null && maxDt != null) {
      _xIsDateTime = true;
      final minMicro = minDt.microsecondsSinceEpoch.toDouble();
      final maxMicro = maxDt.microsecondsSinceEpoch.toDouble();
      final range = maxMicro == minMicro ? 1e6 : maxMicro - minMicro;
      _domainX = (minMicro - 0.1 * range, maxMicro + 0.1 * range);
    } else {
      _xIsDateTime = false;
      final xRange = maxXNum == minXNum ? 10.0 : maxXNum - minXNum;
      _domainX = (minXNum - 0.1 * xRange, maxXNum + 0.1 * xRange);
    }
    final yRange = maxYNum == minYNum ? 10.0 : maxYNum - minYNum;
    _domainY = (minYNum - 0.1 * yRange, maxYNum + 0.1 * yRange);
    return data;
  }

  final variableXInt = g.Variable(accessor: (Map map) => map['x'] as int);
  final variableXNum = g.Variable(accessor: (Map map) => map['x'] as num);
  final variableXDateTime = g.Variable(
    accessor: (Map map) => map['x'] as DateTime,
  );
  final variableXString = g.Variable(accessor: (Map map) => map['x'] as String);

  final variableYInt = g.Variable(accessor: (Map map) => map['y'] as int);
  final variableYNum = g.Variable(accessor: (Map map) => map['y'] as num);
  final variableYString = g.Variable(accessor: (Map map) => map['y'] as String);

  /// Variables for the chart as needed by package `graphic`.
  ///
  /// When [domainX] / [domainY] are provided, explicit axis scales are set so
  /// that the chart shows exactly the selected range.
  Map<String, g.Variable<Map<dynamic, dynamic>, dynamic>> makeVariables(
    List<Map<String, dynamic>> data,
    List<ScatterTrace> traces, {
    (num, num)? domainX,
    (num, num)? domainY,
  }) {
    final out = <String, g.Variable<Map<dynamic, dynamic>, dynamic>>{};
    if (domainX != null) {
      final xScale = _xIsDateTime
          ? g.TimeScale(
              min: DateTime.fromMicrosecondsSinceEpoch(domainX.$1.round()),
              max: DateTime.fromMicrosecondsSinceEpoch(domainX.$2.round()),
            )
          : g.LinearScale(min: domainX.$1, max: domainX.$2);
      out['x'] = switch (traces) {
        (List<ScatterTrace<int, dynamic>> _) => g.Variable(
          accessor: (Map map) => map['x'] as int,
          scale: xScale as g.Scale<num, num>,
        ),
        (List<ScatterTrace<num, dynamic>> _) => g.Variable(
          accessor: (Map map) => map['x'] as num,
          scale: xScale as g.Scale<num, num>,
        ),
        (List<ScatterTrace<DateTime, dynamic>> _) => g.Variable(
          accessor: (Map map) => map['x'] as DateTime,
          scale: xScale as g.Scale<DateTime, num>,
        ),
        (List<ScatterTrace<String, dynamic>> _) => variableXString,
        _ => throw Exception('Unsupported x value type in traces'),
      };
    } else {
      out['x'] = switch (traces) {
        (List<ScatterTrace<int, dynamic>> _) => variableXInt,
        (List<ScatterTrace<num, dynamic>> _) => variableXNum,
        (List<ScatterTrace<DateTime, dynamic>> _) => variableXDateTime,
        (List<ScatterTrace<String, dynamic>> _) => variableXString,
        _ => throw Exception('Unsupported x value type in traces'),
      };
    }
    if (domainY != null) {
      final yScale = g.LinearScale(min: domainY.$1, max: domainY.$2);
      out['y'] = switch (traces) {
        (List<ScatterTrace<dynamic, int>> _) => g.Variable(
          accessor: (Map map) => map['y'] as int,
          scale: yScale as g.Scale<num, num>,
        ),
        (List<ScatterTrace<dynamic, num>> _) => g.Variable(
          accessor: (Map map) => map['y'] as num,
          scale: yScale as g.Scale<num, num>,
        ),
        (List<ScatterTrace<dynamic, String>> _) => variableYString,
        _ => throw Exception('Unsupported y value type in traces'),
      };
    } else {
      out['y'] = switch (traces) {
        (List<ScatterTrace<dynamic, int>> _) => variableYInt,
        (List<ScatterTrace<dynamic, num>> _) => variableYNum,
        // (List<ScatterTrace<dynamic, DateTime>> _) => variableYDateTime,
        (List<ScatterTrace<dynamic, String>> _) => variableYString,
        _ => throw Exception('Unsupported y value type in traces'),
      };
    }
    out['name'] = g.Variable(accessor: (Map map) => map['name'] as String);
    out['text'] = g.Variable(
      accessor: (Map map) => (map['text'] ?? '') as String,
    );
    out['marker.size'] = g.Variable(
      accessor: (Map map) => (map['marker'] as Marker?)?.size.toDouble() ?? 6.0,
    );
    return out;
  }

  /// Custom tooltip renderer that colors the tooltip text to match the
  /// corresponding trace color.
  List<g.MarkElement> _tooltipRenderer(
    Size size,
    Offset anchor,
    Map<int, g.Tuple> selectedTuples,
  ) {
    if (selectedTuples.isEmpty) return [];

    final tuple = selectedTuples.values.first;
    final name = tuple['name'] as String;

    Color traceColor = const Color(0xff595959);
    for (var i = 0; i < widget.traces.length; i++) {
      final trace = widget.traces[i];
      if ((trace.name ?? 'trace $i') == name) {
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

    final textStyle = TextStyle(color: traceColor, fontSize: 12);
    const padding = EdgeInsets.all(5.0);

    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    painter.layout();

    final w = padding.left + painter.width + padding.right;
    final h = padding.top + painter.height + padding.bottom;

    // Position tooltip just right of the anchor point, vertically centered.
    var rect = Rect.fromLTWH(anchor.dx + 10, anchor.dy - h / 2, w, h);
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
  g.BasicLineShape _lineShapeFor(String name, List<ScatterTrace> traces) {
    for (var i = 0; i < traces.length; i++) {
      final trace = traces[i];
      if ((trace.name ?? 'trace $i') == name && trace.mode.contains('lines')) {
        final ls = trace.line?.shape ?? LineShape.linear;
        final dash = _dashPattern(trace.line?.dash ?? Dash.solid);
        return switch (ls) {
          LineShape.spline => g.BasicLineShape(smooth: true, dash: dash),
          LineShape.hv ||
          LineShape.vh => g.BasicLineShape(stepped: true, dash: dash),
          _ => g.BasicLineShape(dash: dash),
        };
      }
    }
    return g.BasicLineShape();
  }

  /// Converts a [Dash] enum value to a dash-pattern list for [g.BasicLineShape].
  List<double>? _dashPattern(Dash dash) => switch (dash) {
    Dash.solid => null,
    Dash.dashed => [6, 4],
    Dash.dotted => [2, 4],
    Dash.longDash => [12, 4],
    Dash.dashDot => [6, 4, 2, 4],
    Dash.longDashDot => [12, 4, 2, 4],
  };

  /// Check the mode of each trace and return the appropriate marks.
  /// The `mode` can be null.
  ///
  List<g.Mark<g.Shape>> makeMarks(List<ScatterTrace> traces) {
    return [
      g.LineMark(
        position: g.Varset('x') * g.Varset('y') / g.Varset('name'),
        shape: g.ShapeEncode(
          encoder: (e) => _lineShapeFor(e['name'] as String, traces),
        ),
        size: g.SizeEncode(
          encoder: (e) {
            for (var i = 0; i < traces.length; i++) {
              final trace = traces[i];
              if ((trace.name ?? 'trace $i') == e['name']) {
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
              if ((trace.name ?? 'trace $i') == e['name']) {
                if (trace.mode.contains('lines')) {
                  return Defaults.colors[i];
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
              if ((trace.name ?? 'trace $i') == e['name']) {
                final mode = trace.mode;
                if (mode.contains('markers')) {
                  return Defaults.colors[i];
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
              if ((trace.name ?? 'trace $i') == e['name']) {
                if (trace.mode.contains('markers')) {
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

  @override
  Widget build(BuildContext context) {
    data = makeData(widget.traces);
    final variables = makeVariables(
      data,
      widget.traces,
      domainX: _filteredDomainX,
      domainY: _filteredDomainY,
    );
    final visibilityKey =
        '${widget.traces.map((t) => t.visible.toString()).join('-')}'
        '|$_filteredDomainX|$_filteredDomainY';
    final chartTitle = widget.layout.title?.text ?? '';
    final xAxisTitle = widget.layout.xAxis?.title?.text ?? '';
    final yAxisTitle = widget.layout.yAxis?.title?.text ?? '';
    final showLegend =
        widget.layout.showLegend && (widget.layout.legend?.visible ?? true);
    final legendSide = widget.layout.legend?.side ?? Side.right;
    final legendMainAxis =
        widget.layout.legend?.mainAxisAlignment ?? MainAxisAlignment.start;
    final legendCrossAxis =
        widget.layout.legend?.crossAxisAlignment ?? CrossAxisAlignment.start;
    final legendAtTop = showLegend && legendSide == Side.top;
    final legendAtBottom = showLegend && legendSide == Side.bottom;
    final legendAtRight = showLegend && legendSide == Side.right;
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
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
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      const leftPad = 40.0;
                                      const rightPad = 10.0;
                                      final usableWidth =
                                          constraints.maxWidth -
                                          leftPad -
                                          rightPad;
                                      return Container(
                                        key: _chartKey,
                                        child: Stack(
                                          children: [
                                            // if shapes are under the chart data
                                            if (widget.layout.shapes != null &&
                                                widget.layout.shapes!.any(
                                                  (s) =>
                                                      s.layer ==
                                                      ShapeLayer.below,
                                                ))
                                              Positioned.fill(
                                                child: IgnorePointer(
                                                  child: CustomPaint(
                                                    painter: ShapesPainter(
                                                      shapes: widget
                                                          .layout
                                                          .shapes!
                                                          .where(
                                                            (s) =>
                                                                s.layer ==
                                                                ShapeLayer
                                                                    .below,
                                                          )
                                                          .toList(),
                                                      domainX:
                                                          (_filteredDomainX ??
                                                          _domainX),
                                                      domainY:
                                                          (_filteredDomainY ??
                                                          _domainY),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            g.Chart(
                                              key: ValueKey(visibilityKey),
                                              padding: (_) =>
                                                  const EdgeInsets.fromLTRB(
                                                    40,
                                                    5,
                                                    10,
                                                    40,
                                                  ),
                                              data: _filteredData.isNotEmpty
                                                  ? _filteredData
                                                  : data,
                                              variables: variables,
                                              marks: makeMarks(widget.traces),
                                              coord: g.RectCoord(
                                                horizontalRange: [0, 1],
                                                verticalRange: [0, 1],
                                              ),
                                              axes: [
                                                g.AxisGuide(
                                                  grid: g.Defaults.strokeStyle,
                                                  label: g.LabelStyle(
                                                    textStyle: Defaults
                                                        .textStyle
                                                        .copyWith(
                                                          color: Colors.black,
                                                        ),
                                                    offset: const Offset(
                                                      0,
                                                      7.5,
                                                    ),
                                                  ),
                                                ),
                                                g.AxisGuide(
                                                  grid: g.Defaults.strokeStyle,
                                                  label: g.LabelStyle(
                                                    textStyle: Defaults
                                                        .textStyle
                                                        .copyWith(
                                                          color: Colors.black,
                                                        ),
                                                    offset: const Offset(
                                                      -7.5,
                                                      0,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              selections: {
                                                'tooltipMouse':
                                                    g.PointSelection(
                                                      on: {g.GestureType.hover},
                                                      nearest: false,
                                                      testRadius: 15.0,
                                                      devices: {
                                                        PointerDeviceKind.mouse,
                                                      },
                                                    ),
                                              },
                                              tooltip: g.TooltipGuide(
                                                renderer: _tooltipRenderer,
                                              ),
                                              gestureStream: _gestureController,
                                            ),
                                            // shapes above the chart data
                                            if (widget.layout.shapes != null &&
                                                widget.layout.shapes!.any(
                                                  (s) =>
                                                      s.layer ==
                                                      ShapeLayer.above,
                                                ))
                                              Positioned.fill(
                                                child: IgnorePointer(
                                                  child: CustomPaint(
                                                    painter: ShapesPainter(
                                                      shapes: widget
                                                          .layout
                                                          .shapes!
                                                          .where(
                                                            (s) =>
                                                                s.layer ==
                                                                ShapeLayer
                                                                    .above,
                                                          )
                                                          .toList(),
                                                      domainX:
                                                          (_filteredDomainX ??
                                                          _domainX),
                                                      domainY:
                                                          (_filteredDomainY ??
                                                          _domainY),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            // if there is a selection
                                            if (_currentSelectionNormalized !=
                                                null)
                                              Positioned(
                                                left:
                                                    leftPad +
                                                    _currentSelectionNormalized![0] *
                                                        usableWidth,
                                                top: 0,
                                                bottom: 0,
                                                width:
                                                    (_currentSelectionNormalized![1] -
                                                        _currentSelectionNormalized![0]) *
                                                    usableWidth,
                                                child: IgnorePointer(
                                                  child: Container(
                                                    color: Colors.grey
                                                        .withAlpha(64),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
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
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ), // Expanded(Column with chart + x-axis title)
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
    final items = List.generate(widget.traces.length, (i) {
      final trace = widget.traces[i];
      final label = trace.name ?? 'trace $i';
      final mode = trace.mode;
      final isVisible = trace.visible == TraceVisibility.on;
      final color = isVisible ? Defaults.colors[i] : Colors.grey.shade400;
      return MouseRegion(
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
                SizedBox(
                  width: 40,
                  height: 14,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (mode.contains('lines'))
                        CustomPaint(
                          size: const Size(40, 2),
                          painter: _LegendLinePainter(
                            color: color,
                            strokeWidth: (trace.line?.width ?? 2.0).toDouble(),
                            dash: _dashPattern(trace.line?.dash ?? Dash.solid),
                          ),
                        ),
                      if (mode.contains('markers'))
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isVisible ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });

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
}
