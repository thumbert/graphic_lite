import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:graphic_lite/graphic_lite.dart';
import 'package:graphic/graphic.dart' as g;

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

  final StreamController<g.GestureEvent> _gestureController =
      StreamController<g.GestureEvent>.broadcast();
  StreamSubscription<g.GestureEvent>? _gestureSub;
  Offset? _dragStart;
  List<Map<String, dynamic>> _filteredData = [];
  List<double>? _currentSelectionNormalized;
  late (num, num) _domainX;

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
          print('Drag ended at local position: $localEnd');

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
          print('Chart width for selection: $width');
          print('Raw selection range in local coordinates: [$left, $right]');

          double nx0 = ((left - leftPad) / width).clamp(0.0, 1.0);
          double nx1 = ((right - leftPad) / width).clamp(0.0, 1.0);
          if (nx1 <= nx0) return;

          final firstMs = _domainX.$1;
          final lastMs = _domainX.$2;
          print('Selected normalized range: [$nx0, $nx1]');
          print('Domain X: [${_domainX.$1}, ${_domainX.$2}]');

          final selMin = firstMs + nx0 * (lastMs - firstMs);
          final selMax = firstMs + nx1 * (lastMs - firstMs);
          print('Selected domain range: [$selMin, $selMax]');

          setState(() {
            _filteredData = data.where((e) {
              final xNum = _xIsDateTime
                  ? (e['x'] as DateTime).microsecondsSinceEpoch.toDouble()
                  : (e['x'] as num).toDouble();
              return xNum >= selMin && xNum <= selMax;
            }).toList();
            // clear live selection overlay once selection is committed
            _currentSelectionNormalized = null;
          });

          _dragStart = null;
        } else if (geg.type == g.GestureType.doubleTap) {
          setState(() {
            _filteredData = [];
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

  List<Map<String, dynamic>> makeData(List<ScatterTrace> traces) {
    var minNum = double.infinity;
    var maxNum = double.negativeInfinity;
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
          if (xVal < minNum) minNum = xVal.toDouble();
          if (xVal > maxNum) maxNum = xVal.toDouble();
        }
        data.add({
          'x': trace.x[j],
          'y': trace.y[j],
          'name': trace.name ?? 'trace $i',
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
      final range = maxNum == minNum ? 10 : maxNum - minNum;
      _domainX = (minNum - 0.1 * range, maxNum + 0.1 * range);
    }
    return data;
  }

  final variableXInt = g.Variable(accessor: (Map map) => map['x'] as int);
  final variableXNum = g.Variable(accessor: (Map map) => map['x'] as num);
  final variableXDateTime = g.Variable(
    accessor: (Map map) => map['x'] as DateTime,
  );
  final variableXString = g.Variable(accessor: (Map map) => map['x'] as String);
  final variableYNum = g.Variable(accessor: (Map map) => map['y'] as num);

  /// Variables for the chart as needed by package `graphic`.
  ///
  Map<String, g.Variable<Map<dynamic, dynamic>, dynamic>> makeVariables(
    List<Map<String, dynamic>> data,
    List<ScatterTrace> traces,
  ) {
    switch (traces.first.x.first) {
      case int _:
        return {
          'x': variableXInt,
          'y': variableYNum,
          'name': g.Variable(accessor: (Map map) => map['name'] as String),
        };
      case num _:
        return {
          'x': variableXNum,
          'y': variableYNum,
          'name': g.Variable(accessor: (Map map) => map['name'] as String),
        };
      case DateTime _:
        return {
          'x': variableXDateTime,
          'y': variableYNum,
          'name': g.Variable(accessor: (Map map) => map['name'] as String),
        };
      case String _:
        return {
          'x': variableXString,
          'y': variableYNum,
          'name': g.Variable(accessor: (Map map) => map['name'] as String),
        };
      default:
        throw Exception(
          'Unsupported x value type: ${traces.first.x.first.runtimeType}',
        );
    }
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
    final xStr = xVal is DateTime ? xVal.toIso8601String() : xVal.toString();
    final text = '($xStr, $yVal) $name';

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

  /// Check the mode of each trace and return the appropriate marks.
  /// The `mode` can be null.
  ///
  List<g.Mark<g.Shape>> makeMarks(List<ScatterTrace> traces) {
    return [
      g.LineMark(
        position: g.Varset('x') * g.Varset('y') / g.Varset('name'),
        color: g.ColorEncode(
          encoder: (e) {
            for (var i = 0; i < traces.length; i++) {
              final trace = traces[i];
              if (trace.visible == TraceVisibility.off) continue;
              if ((trace.name ?? 'trace $i') == e['name']) {
                final mode = trace.mode ?? trace.defaultMode;
                if (mode.contains('lines')) {
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
                final mode = trace.mode ?? trace.defaultMode;
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
              if ((trace.name ?? 'trace $i') == e['name'] &&
                  trace.mode != null) {
                if (trace.mode!.contains('markers')) {
                  return 6.0;
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
    final variables = makeVariables(data, widget.traces);
    final visibilityKey = widget.traces
        .map((t) => t.visible.toString())
        .join('-');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const leftPad = 40.0;
              const rightPad = 10.0;
              final usableWidth = constraints.maxWidth - leftPad - rightPad;
              return Container(
                key: _chartKey,
                child: Stack(
                  children: [
                    g.Chart(
                      key: ValueKey(visibilityKey),
                      padding: (_) => const EdgeInsets.fromLTRB(40, 5, 10, 40),
                      data: _filteredData.isNotEmpty ? _filteredData : data,
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
                        'tooltipMouse': g.PointSelection(
                          on: {g.GestureType.hover},
                          nearest: false,
                          testRadius: 15.0,
                          devices: {PointerDeviceKind.mouse},
                        ),
                      },
                      tooltip: g.TooltipGuide(renderer: _tooltipRenderer),
                      gestureStream: _gestureController,
                    ),
                    // if there is a selection
                    if (_currentSelectionNormalized != null)
                      Positioned(
                        left:
                            leftPad +
                            _currentSelectionNormalized![0] * usableWidth,
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
            },
          ),
        ),
        SizedBox(width: 100, child: _buildLegend()),
      ],
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.traces.length, (i) {
        final trace = widget.traces[i];
        final label = trace.name ?? 'trace $i';
        final mode = trace.mode ?? trace.defaultMode;
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
              padding: const EdgeInsets.symmetric(vertical: 3.0),
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
                          Container(height: 2, color: color),
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
        ); // MouseRegion
      }),
    );
  }
}
