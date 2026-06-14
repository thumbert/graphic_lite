import 'package:graphic_lite/graphic_lite.dart';
/// https://plotly.com/javascript/subplots/#simple-subplot
Chart subplotSimple() {
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
    grid: Grid(rows: 1, columns: 2, pattern: .independent),
  );
  return Chart(traces: traces, layout: layout);
}
