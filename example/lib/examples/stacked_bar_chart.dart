import 'package:graphic_lite/graphic_lite.dart';
/// https://plotly.com/javascript/bar-charts/#stacked-bar-chart
Chart stackedBarChart() {
  final traces = [
    BarTrace(
      x: ['giraffes', 'orangutans', 'monkeys'],
      y: [20, 14, 23],
      name: 'SF Zoo',
    ),
    BarTrace(
      x: ['giraffes', 'orangutans', 'monkeys'],
      y: [12, 18, 29],
      name: 'LA Zoo',
    ),
  ];
  final layout = Layout(
    barMode: .stack,
  );

  return Chart(traces: traces, layout: layout);
}
