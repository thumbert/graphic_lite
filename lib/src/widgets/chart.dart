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
  late List<bool> traceVisible;

  @override
  void initState() {
    super.initState();
    traceVisible = List.filled(widget.traces.length, true);
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
    final data = makeData(widget.traces);
    final variables = makeVariables(data);
    final marks = makeMarks(widget.traces);
    return Stack(
      children: [
        g.Chart(
          padding: (_) => const EdgeInsets.fromLTRB(40, 5, 80, 40),
          data: data,
          variables: variables,
          marks: marks,
          coord: g.RectCoord(horizontalRange: [0, 1], verticalRange: [0, 1]),
          axes: [
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
            // 'choose': IntervalSelection(),
            'touchMove': g.PointSelection(
              on: {
                g.GestureType.tapDown,
                // GestureType.scaleEnd,
                // GestureType.longPressMoveUpdate,
              },
              dim: g.Dim.x,
            ),
            'zoom': g.IntervalSelection(dim: g.Dim.x),
          },
          tooltip: g.TooltipGuide(
            followPointer: [false, true],
            align: Alignment.topLeft,
            offset: const Offset(-20, -20),
          ),
          // crosshair: CrosshairGuide(
          //   followPointer: [false, false],
          // ),
        ),
        Positioned(right: 0, top: 5, width: 100, child: _buildLegend()),
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
