import 'package:flutter/material.dart' hide Title;
import 'package:graphic_lite/graphic_lite.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Basic Scatter Plot',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Basic Scatter Plot'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => LineAndScatterCharts();
}

// https://plotly.com/javascript/line-and-scatter/
class LineAndScatterCharts extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Expanded(child: simple()),
            // const SizedBox(height: 32),
            // Expanded(child: dataLabelsOnHover()),
            // const SizedBox(height: 32),
            // Expanded(child: areaChart()),
            Expanded(child: barChart()),
          ],
        ),
      ),
    );
  }
}

Chart simple() {
  final traces = [
    ScatterTrace(
      x: [1, 2, 3, 4],
      y: [10, 15, 13, 17],
      mode: 'markers',
      name: 'Points',
    ),
    ScatterTrace(
      x: [2, 3, 4, 5],
      y: [16, 5, 11, 9],
      mode: 'lines',
      line: Line(dash: .dotted),
      name: 'Line',
    ),
    ScatterTrace(
      x: [1, 2, 3, 4],
      y: [12, 9, 15, 12],
      mode: 'lines+markers',
      name: 'Points and Line',
    ),
  ];
  final layout = Layout(
    title: Title('Simple Scatter Plot'),
    xAxis: XAxis(title: Title('X Axis')),
    yAxis: YAxis(title: Title('Y Axis')),
  );
  return Chart(traces: traces, layout: layout);
}

Chart dataLabelsOnHover() {
  final traces = [
    ScatterTrace<num, num>(
      x: [1, 2, 3, 4, 5],
      y: [1, 6, 3, 6, 1],
      mode: 'markers',
      name: 'Team A',
      text: ['A-1', 'A-2', 'A-3', 'A-4', 'A-5'],
      marker: [Marker(size: 12)],
    ),
    ScatterTrace<num, num>(
      x: [1.5, 2.5, 3.5, 4.5, 5.5],
      y: [4, 1, 7, 1, 4],
      mode: 'markers',
      name: 'Team B',
      text: ['B-a', 'B-b', 'B-c', 'B-d', 'B-e'],
      marker: [Marker(size: 12)],
    ),
  ];
  final layout = Layout(
    title: Title('Data labels hover'),
    xAxis: XAxis(range: (0.75, 5.25)),
    yAxis: YAxis(range: (0, 8)),
    shapes: [
      Shape(
        type: ShapeType.rectangle,
        x0: 1.25,
        x1: 2.75,
        xRef: 'x',
        y0: 0,
        y1: 1,
        yRef: 'paper',
        fillColor: Colors.blue.withAlpha(64),
        layer: ShapeLayer.below,
      ),
    ],
  );
  return Chart(traces: traces, layout: layout);
}

/// See https://plotly.com/javascript/filled-area-plots/
Chart areaChart() {
  final traces = [
    ScatterTrace(x: [1, 2, 3, 4], y: [0, 2, 3, 5], fill: Fill.toZeroY),
    ScatterTrace(x: [1, 2, 3, 4], y: [3, 5, 1, 7], fill: Fill.toNextY),
  ];
  return Chart(traces: traces);
}

Chart barChart() {
  final traces = [
    BarTrace(x: ['giraffes', 'orangutans', 'monkeys'], y: [20, 14, 23]),
  ];
  return Chart(traces: traces);
}
