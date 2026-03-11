import 'package:flutter/material.dart';
import 'package:gallery/assets/caiso_prices.dart';
import 'package:graphic_lite/graphic_lite.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/timezone.dart';

void main() {
  initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Series Plot',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Time Series Plot'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

final tz = getLocation('America/Los_Angeles');

class _MyHomePageState extends State<MyHomePage> {
  final traces = [
    ScatterTrace<TZDateTime>(
      x: prices[0]['x']!.map<TZDateTime>((e) => TZDateTime.parse(tz, e)).toList(),
      y: (prices[0]['y']! as List).cast<num>(),
      name: 'NP15', //prices[0]['name']!,
    ),
    ScatterTrace<TZDateTime>(
      x: prices[1]['x']!.map<TZDateTime>((e) => TZDateTime.parse(tz, e)).toList(),
      y: (prices[1]['y']! as List).cast<num>(),
      name: 'SP15', //prices[1]['name']!,
    ),
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
