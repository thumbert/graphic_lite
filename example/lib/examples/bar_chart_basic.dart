import 'package:graphic_lite/graphic_lite.dart';

/// https://plotly.com/javascript/bar-charts/#basic-bar-chart
Chart basicBarChart() {
  return Chart(
    traces: [
      BarTrace(x: ['giraffes', 'orangutans', 'monkeys'], y: [20, 14, 23]),
    ],
  );
}
