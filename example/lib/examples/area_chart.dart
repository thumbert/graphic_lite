import 'package:graphic_lite/graphic_lite.dart';
/// See https://plotly.com/javascript/filled-area-plots/
Chart areaChart() {
  final traces = [
    ScatterTrace(x: [1, 2, 3, 4], y: [0, 2, 3, 5], fill: .toZeroY),
    ScatterTrace(x: [1, 2, 3, 4], y: [3, 5, 1, 7], fill: .toNextY),
  ];
  return Chart(traces: traces);
}
