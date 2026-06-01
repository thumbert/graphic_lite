import 'package:graphic_lite/graphic_lite.dart';
/// https://plotly.com/javascript/subplots/#custom-sized-subplot
Chart simpleSubplot() {
  final traces = [
    ScatterTrace(
      x: [1, 2, 3],
      y: [4, 5, 6],
    ),
    ScatterTrace(
      x: [20, 30, 40],
      y: [50, 60, 70],
      xAxis: 'x2',
      yAxis: 'y2',
    ),
  ];
  final layout = Layout(
    xAxis: XAxis(domain: (0, 0.7)),
    xAxis2: XAxis(domain: (0.8, 1)),
    yAxis2: YAxis(anchor: 'x2'),
  );
  return Chart(traces: traces, layout: layout);
}
