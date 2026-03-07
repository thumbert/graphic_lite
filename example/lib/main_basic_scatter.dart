import 'package:flutter/material.dart';
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
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ScatterTrace> traces = [
    ScatterTrace(x: [1, 2, 3, 4], y: [10, 15, 13, 17], mode: 'markers'),
    ScatterTrace(x: [2, 3, 4, 5], y: [16, 5, 11, 9], mode: 'lines'),
    ScatterTrace(x: [1, 2, 3, 4], y: [12, 9, 15, 12], mode: 'lines+markers'),
  ];

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
          children: <Widget>[Expanded(child: Chart(traces: traces))],
        ),
      ),
    );
  }
}
