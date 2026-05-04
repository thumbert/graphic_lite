import 'package:flutter/material.dart' hide Title;
import 'package:flutter/services.dart';
import 'package:gallery/examples/area_chart.dart';
import 'package:gallery/examples/basic_bar_chart.dart';
import 'package:gallery/examples/data_labels_on_hover.dart';
import 'package:gallery/examples/grouped_bar_chart.dart';
import 'package:gallery/examples/simple_scatter_plot.dart';
import 'package:gallery/examples/stacked_bar_chart.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

late final Highlighter _dartLightHighlighter;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the highlighter.
  await Highlighter.initialize(['dart']);

  // Load the default light theme and create a highlighter.
  var lightTheme = await HighlighterTheme.loadLightTheme();
  _dartLightHighlighter = Highlighter(language: 'dart', theme: lightTheme);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Example gallery',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Example gallery'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => GalleryCharts();
}

// https://plotly.com/javascript/line-and-scatter/
class GalleryCharts extends State<MyHomePage> {
  int _selectedIndex = 0;
  final List<String> _source = List.filled(_navItems.length, '');

  @override
  void initState() {
    super.initState();
    rootBundle
        .loadString('lib/examples/simple_scatter_plot.dart')
        .then((src) => setState(() => _source[0] = src));
    rootBundle
        .loadString('lib/examples/data_labels_on_hover.dart')
        .then((src) => setState(() => _source[1] = src));
    rootBundle
        .loadString('lib/examples/area_chart.dart')
        .then((src) => setState(() => _source[2] = src));
    rootBundle
        .loadString('lib/examples/basic_bar_chart.dart')
        .then((src) => setState(() => _source[3] = src));
    rootBundle
        .loadString('lib/examples/stacked_bar_chart.dart')
        .then((src) => setState(() => _source[4] = src));
    rootBundle
        .loadString('lib/examples/grouped_bar_chart.dart')
        .then((src) => setState(() => _source[5] = src));
  }

  static const _navItems = [
    'Simple Scatter Plot',
    'Data Labels on Hover',
    'Area Chart',
    'Basic Bar Chart',
    'Stacked Bar Chart',
    'Grouped Bar Chart',
  ];

  Widget _buildContent() {
    var highlightedCode = _dartLightHighlighter.highlight(
      _source[_selectedIndex].split('\n').skip(2).join('\n'),
    );
    List<Widget> widgets = [];

    switch (_selectedIndex) {
      case 0:
        widgets = [
          SizedBox(width: 800, height: 500, child: simpleScatterPlot()),
          const SizedBox(height: 24),
          Text('Mouse over the points to see data labels.'),
          Text('Click a legend item to toggle traces.'),
          Text('Use the mouse to select an area on the chart to zoom in.'),
        ];
        break;
      case 1:
        widgets = [
          SizedBox(width: 800, height: 500, child: dataLabelsOnHover()),
          const SizedBox(height: 24),
          Text('Mouse over the points to see data labels.'),
          Text('Note how to define the rectangular blue shape in the layout.'),
        ];
        break;
      case 2:
        widgets = [SizedBox(width: 800, height: 500, child: areaChart())];
        break;
      case 3:
        widgets = [SizedBox(width: 800, height: 500, child: basicBarChart())];
        break;
      case 4:
        widgets = [SizedBox(width: 800, height: 500, child: stackedBarChart())];
        break;
      case 5:
        widgets = [SizedBox(width: 800, height: 500, child: groupedBarChart())];
        break;
      default:
        widgets = [
          SizedBox(width: 800, height: 500, child: simpleScatterPlot()),
          const SizedBox(height: 24),
          Text('Mouse over the points to see data labels.'),
          Text('Click a legend item to toggle traces.'),
        ];
    }
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...widgets,
          const SizedBox(height: 24),
          Text('Source code:', style: Theme.of(context).textTheme.titleMedium),
          SelectableText.rich(
            highlightedCode,
            style: TextStyle(fontFamily: 'UbuntuMono'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final selected = index == _selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        backgroundColor: selected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Colors.transparent,
                        foregroundColor: selected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => setState(() => _selectedIndex = index),
                      child: Text(_navItems[index]),
                    ),
                  );
                },
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }
}
