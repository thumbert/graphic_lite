import 'package:flutter/material.dart' hide Title;
import 'package:flutter/services.dart';
import 'package:gallery/examples/bar_chart_horizontal.dart';
import 'package:gallery/examples/bar_chart_individual_widths.dart';
import 'package:gallery/examples/line_chart_bar_chart.dart';
import 'package:gallery/examples/subplot_custom_sized.dart';
import 'package:gallery/examples/subplot_simple.dart';
import 'package:gallery/examples/two_y_axes.dart';
import 'package:syntax_highlight/syntax_highlight.dart';

import 'examples/area_chart.dart';
import 'examples/bar_chart_basic.dart';
import 'examples/data_labels_on_hover.dart';
import 'examples/bar_chart_grouped.dart';
import 'examples/simple_scatter_plot.dart';
import 'examples/simple_text_annotation.dart';
import 'examples/bar_chart_stacked.dart';

late final Highlighter _dartLightHighlighter;

/// NOTE: This app only works for web.  Linux gets confused with the highlighter 
/// package and fails.  
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Highlighter.initialize(['dart']);
  var lightTheme = await HighlighterTheme.loadLightTheme();
  _dartLightHighlighter = Highlighter(language: 'dart', theme: lightTheme);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Examples gallery',
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
  String _selectedTitle = _navItems[0].$1;
  final Map<String, String> _source = {};

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _navItems.length; i++) {
      rootBundle
          .loadString('lib/examples/${_navItems[i].$2}')
          .then((src) => setState(() => _source[_navItems[i].$1] = src));
    }
  }

  static const _navItems = [
    ('Simple Scatter Plot', 'simple_scatter_plot.dart'),
    ('Data Labels on Hover', 'data_labels_on_hover.dart'),
    ('Two Y Axes', 'two_y_axes.dart'),
    ('Area Chart', 'area_chart.dart'),
    ('Basic Bar Chart', 'bar_chart_basic.dart'),
    ('Horizontal Bar Chart', 'bar_chart_horizontal.dart'),
    ('Stacked Bar Chart', 'bar_chart_stacked.dart'),
    ('Grouped Bar Chart', 'bar_chart_grouped.dart'),
    ('Bar Chart with different widths', 'bar_chart_individual_widths.dart'),
    ('Line Chart and Bar Chart', 'line_chart_bar_chart.dart'),
    ('Simple Text Annotation', 'simple_text_annotation.dart'),
    ('Subplot Simple', 'subplot_simple.dart'),
    ('Subplot Custom Sized', 'subplot_custom_sized.dart'),
  ];

  String extractContent(String src) {
    final lines = src.split('\n');
    final index = lines.indexWhere((line) => line.startsWith('Chart'));
    return lines.skip(index).join('\n');
  }

  Widget _buildContent() {
    final src = _source[_selectedTitle];
    if (src == null) {
      return const Center(child: CircularProgressIndicator());
    }
    var highlightedCode = _dartLightHighlighter.highlight(extractContent(src));
    List<Widget> widgets = [];

    switch (_selectedTitle) {
      case 'Simple Scatter Plot':
        widgets = [
          SizedBox(width: 800, height: 500, child: simpleScatterPlot()),
          const SizedBox(height: 24),
          Text('Mouse over the points to see data labels.'),
          Text('Click a legend item to toggle traces.'),
          Text('Use the mouse to select an area on the chart to zoom in.'),
        ];
        break;
      case 'Data Labels on Hover':
        widgets = [
          SizedBox(width: 800, height: 500, child: dataLabelsOnHover()),
          const SizedBox(height: 24),
          Text('Mouse over the points to see data labels.'),
          Text('Note how to define the rectangular blue shape in the layout.'),
        ];
        break;
      case 'Two Y Axes':
        widgets = [SizedBox(width: 800, height: 500, child: twoYAxes())];
        break;
      case 'Area Chart':
        widgets = [SizedBox(width: 800, height: 500, child: areaChart())];
        break;
      case 'Basic Bar Chart':
        widgets = [SizedBox(width: 800, height: 500, child: basicBarChart())];
        break;
      case 'Horizontal Bar Chart':
        widgets = [SizedBox(width: 800, height: 500, child: horizontalBarChart())];
        break;  
      case 'Stacked Bar Chart':
        widgets = [SizedBox(width: 800, height: 500, child: stackedBarChart())];
        break;
      case 'Grouped Bar Chart':
        widgets = [SizedBox(width: 800, height: 500, child: groupedBarChart())];
        break;
      case 'Bar Chart with different widths':
        widgets = [
          SizedBox(width: 600, height: 400, child: barChartIndividualWidths()),
        ];
        break;  
      case 'Line Chart and Bar Chart':
        widgets = [
          SizedBox(width: 800, height: 500, child: lineChartAndBarChart()),
        ];
        break;
      case 'Simple Text Annotation':
        widgets = [
          SizedBox(width: 800, height: 500, child: simpleTextAnnotation()),
        ];
        break;
      case 'Subplot Simple':
        widgets = [
          SizedBox(width: 800, height: 500, child: subplotSimple()),  
        ];
        break;
      case 'Subplot Custom Sized':
        widgets = [
          SizedBox(width: 800, height: 500, child: subplotCustomSized()),  
        ];
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
                  final selected = _navItems[index].$1 == _selectedTitle;
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
                      onPressed: () =>
                          setState(() => _selectedTitle = _navItems[index].$1),
                      child: Text(_navItems[index].$1),
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
