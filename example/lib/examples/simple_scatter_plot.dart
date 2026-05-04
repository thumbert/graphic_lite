import 'package:graphic_lite/graphic_lite.dart';

Chart simpleScatterPlot() {
  final traces = [
    ScatterTrace(
      x: [1, 2, 3, 4],
      y: [10, 15, 13, 17],
      mode: .markers,
      name: 'Points',
    ),
    ScatterTrace(
      x: [2, 3, 4, 5],
      y: [16, 5, 11, 9],
      mode: .lines,
      line: Line(dash: .dotted),
      name: 'Line',
    ),
    ScatterTrace(
      x: [1, 2, 3, 4],
      y: [12, 9, 15, 12],
      mode: .linesMarkers,
      name: 'Points and Line',
    ),
  ];
  final layout = Layout(
    title: Title('Simple Scatter Plot'),
    xAxis: XAxis(title: Title('X Axis')),
    yAxis: YAxis(title: Title('Y Axis')),
  );
  return Chart(traces: traces, layout: layout);
}
