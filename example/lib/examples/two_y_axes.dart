import 'package:flutter/material.dart' hide Title;
import 'package:graphic_lite/graphic_lite.dart';

/// https://plotly.com/javascript/multiple-axes/#two-y-axes
Chart twoYAxes() {
  final traces = [
    ScatterTrace(x: [1, 2, 3], y: [40, 50, 60], name: 'yaxis data'),
    ScatterTrace(x: [2, 3, 4], y: [4, 5, 6], name: 'yaxis2 data', yAxis: 'y2'),
  ];
  final layout = Layout(
    title: Title('Double Y Axis Example'),
    yAxis: YAxis(title: Title('yaxis title')),
    yAxis2: YAxis(
      title: Title('yaxis2 title', style: TextStyle(color: Colors.purple)),
      overlaying: 'y',
      side: .right,
    ),
  );
  return Chart(traces: traces, layout: layout);
}
