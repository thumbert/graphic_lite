import 'package:graphic_lite/graphic_lite.dart';
/// https://plotly.com/javascript/bar-charts/#grouped-bar-chart
Chart groupedBarChart() {
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
    barMode: .group,
  );

  return Chart(traces: traces, layout: layout);
}
