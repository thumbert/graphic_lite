import 'dart:ui';

import 'package:graphic_lite/graphic_lite.dart';

Chart simpleAnnotation() {
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
        y: 3,
        xRef: 'x',
        yRef: 'y',
        
        text: 'Annotation Text',
        arrow: Arrow(color: const Color(0xFF800080)),
      ),
    ],
  );
  return Chart(traces: traces, layout: layout);
}
