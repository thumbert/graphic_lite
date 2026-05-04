import 'package:flutter/widgets.dart';
import 'package:graphic_lite/graphic_lite.dart';

Chart simpleTextAnnotation() {
  final traces = [
    ScatterTrace(
      x: [0, 1, 2, 3, 4, 5, 6, 7, 8],
      y: [0, 1, 3, 2, 4, 3, 4, 6, 5],
    ),
    ScatterTrace(
      x: [0, 1, 2, 3, 4, 5, 6, 7, 8],
      y: [0, 4, 5, 1, 2, 2, 3, 4, 2],
    ),
  ];
  final layout = Layout(
    showLegend: false,
    annotations: [
      Annotation(
        x: 2,
        y: 5,
        xRef: 'x',
        yRef: 'y',
        text: Text('Annotation Text'),
        arrow: Arrow(color: const Color(0xFF800080), ax: 0, ay: -40, width: 2),
      ),
    ],
  );
  return Chart(traces: traces, layout: layout);
}
