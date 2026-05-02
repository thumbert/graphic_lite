import 'package:graphic_lite/graphic_lite.dart';
/// See https://plotly.com/javascript/filled-area-plots/
Chart areaChart() {
  final traces = [
    ScatterTrace(x: [1, 2, 3, 4], y: [0, 2, 3, 5], fill: Fill.toZeroY),
    ScatterTrace(x: [1, 2, 3, 4], y: [3, 5, 1, 7], fill: Fill.toNextY),
  ];
  return Chart(traces: traces);
}
