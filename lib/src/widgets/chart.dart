import 'dart:async';

import 'package:flutter/material.dart';
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
  late List<bool> traceVisible;
  late List<Map<String, dynamic>> data;

  final StreamController<g.GestureEvent> _gestureController =
      StreamController<g.GestureEvent>.broadcast();
  StreamSubscription<g.GestureEvent>? _gestureSub;
  Offset? _dragStart;
  List<Map<String, dynamic>> _filteredData = [];
  List<double>? _currentSelectionNormalized;

  @override
  void initState() {
    super.initState();
    traceVisible = List.filled(widget.traces.length, true);
    _gestureSub = _gestureController.stream.listen((event) {
      try {
        final ge = event as g.GestureEvent;
        final geg = ge.gesture;

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

          double nx0 = ((left - leftPad) / width).clamp(0.0, 1.0);
          double nx1 = ((right - leftPad) / width).clamp(0.0, 1.0);
          if (nx1 <= nx0) return;

          final firstMs = 1.0;
          final lastMs = 5.0;
          final selMin = firstMs + nx0 * (lastMs - firstMs);
          final selMax = firstMs + nx1 * (lastMs - firstMs);

          setState(() {
            _filteredData = data.where((e) {
              return e['x'] >= selMin && e['x'] <= selMax;
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

  List<Map<String, dynamic>> makeData(List<ScatterTrace> traces) {
    final data = <Map<String, dynamic>>[];
    for (var i = 0; i < traces.length; i++) {
      if (!traceVisible[i]) continue;
      final trace = traces[i];
      for (var j = 0; j < trace.x.length; j++) {
        data.add({
          'x': trace.x[j],
          'y': trace.y[j],
          'name': trace.name ?? 'trace $i',
        });
      }
    }
    return data;
  }

  Map<String, g.Variable<Map<dynamic, dynamic>, dynamic>> makeVariables(
    List<Map<String, dynamic>> data,
  ) {
    return <String, g.Variable<Map<dynamic, dynamic>, dynamic>>{
      'x': g.Variable(accessor: (Map map) => map['x'] as int),
      'y': g.Variable(accessor: (Map map) => map['y'] as int),
      'name': g.Variable(accessor: (Map map) => map['name'] as String),
    };
  }

  /// Check the mode of each trace and return the appropriate marks.
  ///
  List<g.Mark<g.Shape>> makeMarks(List<ScatterTrace> traces) {
    return [
      g.LineMark(
        position: g.Varset('x') * g.Varset('y') / g.Varset('name'),
        color: g.ColorEncode(
          encoder: (e) {
            if (e['name'] == 'trace 1') {
              return Defaults.colors[1];
            } else if (e['name'] == 'trace 2') {
              return Defaults.colors[2];
            } else {
              return Colors.transparent;
            }
          },
        ),
      ),
      g.PointMark(
        color: g.ColorEncode(variable: 'name', values: Defaults.colors),
        size: g.SizeEncode(
          encoder: (e) {
            if (e['name'] == 'trace 0' || e['name'] == 'trace 2') {
              return 6.0;
            } else {
              return 0.0;
            }
          },
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    data = makeData(widget.traces);
    final variables = makeVariables(data);
    final marks = makeMarks(widget.traces);
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
                      padding: (_) => const EdgeInsets.fromLTRB(40, 5, 80, 40),
                      data: _filteredData.isNotEmpty ? _filteredData : data,
                      variables: variables,
                      marks: marks,
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
                        // 'choose': IntervalSelection(),
                        'touchMove': g.PointSelection(
                          on: {g.GestureType.tapDown},
                          dim: g.Dim.x,
                        ),
                        // 'zoom': g.IntervalSelection(dim: g.Dim.x),
                      },
                      tooltip: g.TooltipGuide(
                        followPointer: [false, true],
                        align: Alignment.topLeft,
                        offset: const Offset(-20, -20),
                      ),
                      crosshair: g.CrosshairGuide(
                        followPointer: [false, false],
                      ),
                      gestureStream: _gestureController,
                    ),
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
        final label = widget.traces[i].name ?? 'trace $i';
        final mode = widget.traces[i].mode ?? '';
        final isVisible = traceVisible[i];
        final color = isVisible ? Defaults.colors[i] : Colors.grey.shade400;
        return GestureDetector(
          onTap: () => setState(() => traceVisible[i] = !traceVisible[i]),
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
        );
      }),
    );
  }
}
