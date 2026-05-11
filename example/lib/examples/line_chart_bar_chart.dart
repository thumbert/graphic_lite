import 'package:graphic_lite/graphic_lite.dart';
/// https://plotly.com/javascript/graphing-multiple-chart-types/#line-chart-and-a-bar-chart
Chart lineChartAndBarChart() {
  final traces = [
    ScatterTrace(x: [0, 1, 2, 3, 4, 5], y: [1.5, 1, 1.3, 0.7, 0.8, 0.9]),
    BarTrace(x: [0, 1, 2, 3, 4, 5], y: [1, 0.5, 0.7, -1.2, 0.3, 0.4]),
  ];
  return Chart(traces: traces);
}
