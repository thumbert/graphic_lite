import 'package:flutter/material.dart' hide Title;
import 'package:graphic_lite/graphic_lite.dart';

Chart dataLabelsOnHover() {
  final traces = [
    ScatterTrace(
      x: [1, 2, 3, 4, 5],
      y: [1, 6, 3, 6, 1],
      mode: 'markers',
      name: 'Team A',
      text: ['A-1', 'A-2', 'A-3', 'A-4', 'A-5'],
      marker: [Marker(size: 12)],
    ),
    ScatterTrace(
      x: [1.5, 2.5, 3.5, 4.5, 5.5],
      y: [4, 1, 7, 1, 4],
      mode: 'markers',
      name: 'Team B',
      text: ['B-a', 'B-b', 'B-c', 'B-d', 'B-e'],
      marker: [Marker(size: 12)],
    ),
  ];
  final layout = Layout(
    title: Title('Data labels hover'),
    xAxis: XAxis(range: (0.75, 5.25)),
    yAxis: YAxis(range: (0, 8)),
    shapes: [
      Shape(
        type: .rectangle,
        x0: 1.25,
        x1: 2.75,
        xRef: 'x',
        y0: 0,
        y1: 1,
        yRef: 'paper',
        fillColor: Colors.blue.withAlpha(64),
        layer: .below,
      ),
    ],
  );
  return Chart(traces: traces, layout: layout);
}
