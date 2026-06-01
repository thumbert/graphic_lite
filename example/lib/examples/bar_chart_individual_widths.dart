import 'package:graphic_lite/graphic_lite.dart';
/// https://plotly.com/javascript/bar-charts/#customizing-individual-bar-widths
Chart barChartIndividualWidths() {
  final traces = [
    BarTrace(
      x: [1, 2, 3, 5.5, 10],
      y: [10, 8, 6, 4, 2],
      width: [0.8, 0.8, 0.8, 3.5, 4],
    ),
  ];
  return Chart(traces: traces);
}
