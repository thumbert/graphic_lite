import 'package:graphic_lite/graphic_lite.dart';

/// https://plotly.com/javascript/horizontal-bar-charts/
Chart horizontalBarChart() {
  return Chart(
    traces: [
      BarTrace(
        x: [20, 14, 23],
        y: ['giraffes', 'orangutans', 'monkeys'],
        orientation: .horizontal,
      ),
    ],
  );
}

