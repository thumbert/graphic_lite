import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphic_lite/src/display/enums.dart';
import 'package:graphic_lite/src/display/marker.dart';
import 'package:graphic_lite/src/display/traces/trace_bar.dart';
import 'package:graphic_lite/src/display/traces/trace_scatter.dart';
import 'package:graphic_lite/src/display/graphics/chart_data.dart';

void main() {
  group('buildChartData', () {
    // ------------------------------------------------------------------ basic
    group('basic numeric x/y', () {
      test('returns one row per data point', () {
        final trace = ScatterTrace(x: [1, 2, 3], y: [10, 20, 30]);
        final result = buildChartData([trace]);
        expect(result.data, hasLength(3));
      });

      test('data rows contain correct x and y values', () {
        final trace = ScatterTrace(x: [1, 2, 3], y: [10, 20, 30]);
        final result = buildChartData([trace]);
        expect(result.data[0]['x'], equals(1));
        expect(result.data[0]['y'], equals(10));
        expect(result.data[2]['x'], equals(3));
        expect(result.data[2]['y'], equals(30));
      });

      test('name defaults to "trace 0" when not provided', () {
        final trace = ScatterTrace(x: [1], y: [1]);
        final result = buildChartData([trace]);
        expect(result.data[0]['name'], equals('trace 0'));
      });

      test('name uses trace.name when provided', () {
        final trace = ScatterTrace(x: [1], y: [1], name: 'series A');
        final result = buildChartData([trace]);
        expect(result.data[0]['name'], equals('series A'));
      });

      test('xIsDateTime is false for numeric x', () {
        final trace = ScatterTrace(x: [1, 2], y: [1, 2]);
        final result = buildChartData([trace]);
        expect(result.xIsDateTime, isFalse);
      });

      test('domainX has 10 % margins', () {
        final trace = ScatterTrace(x: [0, 10], y: [0, 10]);
        final result = buildChartData([trace]);
        // range = 10, margin = 1 → domain = (-1, 11)
        expect(result.domainX.$1, closeTo(-1.0, 1e-9));
        expect(result.domainX.$2, closeTo(11.0, 1e-9));
      });

      test('domainY has 10 % margins', () {
        final trace = ScatterTrace(x: [0, 10], y: [0, 100]);
        final result = buildChartData([trace]);
        // range = 100, margin = 10 → domain = (-10, 110)
        expect(result.domainY.$1, closeTo(-10.0, 1e-9));
        expect(result.domainY.$2, closeTo(110.0, 1e-9));
      });

      test('domainX uses 10-unit fallback when all x values are equal', () {
        final trace = ScatterTrace(x: [5, 5], y: [1, 2]);
        final result = buildChartData([trace]);
        // xRange fallback = 10 → domain = (5 - 1, 5 + 1)
        expect(result.domainX.$1, closeTo(4.0, 1e-9));
        expect(result.domainX.$2, closeTo(6.0, 1e-9));
      });
    });

    // --------------------------------------------------------------- DateTime
    group('DateTime x axis', () {
      final t0 = DateTime(2024, 1, 1);
      final t1 = DateTime(2024, 1, 11);

      test('xIsDateTime is true', () {
        final trace = ScatterTrace(x: [t0, t1], y: [1.0, 2.0]);
        final result = buildChartData([trace]);
        expect(result.xIsDateTime, isTrue);
      });

      test('domainX min/max bracket the data with 10 % margins', () {
        final trace = ScatterTrace(x: [t0, t1], y: [1.0, 2.0]);
        final result = buildChartData([trace]);
        final minMicro = t0.microsecondsSinceEpoch.toDouble();
        final maxMicro = t1.microsecondsSinceEpoch.toDouble();
        final range = maxMicro - minMicro;
        expect(result.domainX.$1, closeTo(minMicro - 0.1 * range, 1e-3));
        expect(result.domainX.$2, closeTo(maxMicro + 0.1 * range, 1e-3));
      });

      test('single-point DateTime x uses 1-second fallback range', () {
        final trace = ScatterTrace(x: [t0, t0], y: [1.0, 2.0]);
        final result = buildChartData([trace]);
        final micro = t0.microsecondsSinceEpoch.toDouble();
        const fallback = 1e6; // 1 second in microseconds
        expect(result.domainX.$1, closeTo(micro - 0.1 * fallback, 1e-3));
        expect(result.domainX.$2, closeTo(micro + 0.1 * fallback, 1e-3));
      });
    });

    // -------------------------------------------------------- multiple traces
    group('multiple traces', () {
      test('data from all traces is concatenated', () {
        final t1 = ScatterTrace(x: [1, 2], y: [10, 20], name: 'A');
        final t2 = ScatterTrace(x: [3, 4], y: [30, 40], name: 'B');
        final result = buildChartData([t1, t2]);
        expect(result.data, hasLength(4));
        expect(result.data.map((e) => e['name']).toSet(), {'A', 'B'});
      });

      test('domainX spans all traces', () {
        final t1 = ScatterTrace(x: [0, 5], y: [1, 1], name: 'A');
        final t2 = ScatterTrace(x: [5, 10], y: [1, 1], name: 'B');
        final result = buildChartData([t1, t2]);
        expect(result.domainX.$1, lessThan(0));
        expect(result.domainX.$2, greaterThan(10));
      });
    });

    // ------------------------------------------------------- TraceVisibility
    group('TraceVisibility', () {
      test('off traces are excluded from data', () {
        final trace = ScatterTrace(x: [1, 2, 3], y: [1, 2, 3]);
        trace.visible = TraceVisibility.off;
        final result = buildChartData([trace]);
        expect(result.data, isEmpty);
      });

      test('only visible traces contribute to domain', () {
        final visible = ScatterTrace(x: [0, 10], y: [0, 10], name: 'vis');
        final hidden = ScatterTrace(x: [100, 200], y: [100, 200], name: 'hid');
        hidden.visible = TraceVisibility.off;
        final result = buildChartData([visible, hidden]);
        expect(result.domainX.$2, lessThan(100));
        expect(result.domainY.$2, lessThan(100));
      });
    });

    // ----------------------------------------------------------------- text
    group('text field', () {
      test('single text element is broadcast to all points', () {
        final trace = ScatterTrace(x: [1, 2, 3], y: [1, 2, 3], text: ['label']);
        final result = buildChartData([trace]);
        for (final row in result.data) {
          expect(row['text'], equals('label'));
        }
      });

      test('per-point text is assigned correctly', () {
        final trace = ScatterTrace(
          x: [1, 2, 3],
          y: [1, 2, 3],
          text: ['a', 'b', 'c'],
        );
        final result = buildChartData([trace]);
        expect(result.data[0]['text'], equals('a'));
        expect(result.data[1]['text'], equals('b'));
        expect(result.data[2]['text'], equals('c'));
      });

      test('rows have no text key when trace.text is null', () {
        final trace = ScatterTrace(x: [1], y: [1]);
        final result = buildChartData([trace]);
        expect(result.data[0].containsKey('text'), isFalse);
      });
    });

    // --------------------------------------------------------------- marker
    group('marker field', () {
      test('marker is null when trace has no marker (lines-only mode)', () {
        final trace = ScatterTrace(x: [1, 2], y: [1, 2], mode: 'lines');
        final result = buildChartData([trace]);
        expect(result.data[0]['marker'], isNull);
      });

      test('single marker is broadcast to all points', () {
        final m = Marker(size: 8, color: Colors.red);
        final trace = ScatterTrace(
          x: [1, 2, 3],
          y: [1, 2, 3],
          mode: 'markers',
          marker: [m],
        );
        final result = buildChartData([trace]);
        for (final row in result.data) {
          expect(row['marker'], same(m));
        }
      });

      test('per-point markers are assigned correctly', () {
        final m0 = Marker(size: 4, color: Colors.blue);
        final m1 = Marker(size: 8, color: Colors.red);
        final m2 = Marker(size: 12, color: Colors.green);
        final trace = ScatterTrace(
          x: [1, 2, 3],
          y: [1, 2, 3],
          mode: 'markers',
          marker: [m0, m1, m2],
        );
        final result = buildChartData([trace]);
        expect(result.data[0]['marker'], same(m0));
        expect(result.data[1]['marker'], same(m1));
        expect(result.data[2]['marker'], same(m2));
      });
    });

    // -------------------------------------------------------------- y_fill
    group('y_fill for Fill.toNextY', () {
      test('y_fill key is present when fill == toNextY', () {
        final base = ScatterTrace(x: [1, 2], y: [5.0, 10.0], name: 'base');
        final fill = ScatterTrace(
          x: [1, 2],
          y: [8.0, 15.0],
          name: 'fill',
          fill: Fill.toNextY,
        );
        final result = buildChartData([base, fill]);
        // The fill trace rows should have a y_fill key.
        final fillRows = result.data.where((r) => r['name'] == 'fill').toList();
        for (final row in fillRows) {
          expect(row.containsKey('y_fill'), isTrue);
        }
      });

      test('y_fill values match the previous visible trace y values', () {
        final base = ScatterTrace(x: [1, 2], y: [5.0, 10.0], name: 'base');
        final fill = ScatterTrace(
          x: [1, 2],
          y: [8.0, 15.0],
          name: 'fill',
          fill: Fill.toNextY,
        );
        final result = buildChartData([base, fill]);
        final fillRows = result.data.where((r) => r['name'] == 'fill').toList();
        expect(fillRows[0]['y_fill'], closeTo(5.0, 1e-9));
        expect(fillRows[1]['y_fill'], closeTo(10.0, 1e-9));
      });

      test('y_fill key is absent when fill == none', () {
        final trace = ScatterTrace(x: [1, 2], y: [1.0, 2.0]);
        final result = buildChartData([trace]);
        for (final row in result.data) {
          expect(row.containsKey('y_fill'), isFalse);
        }
      });
    });

    // ------------------------------------------------------------- BarTrace
    group('BarTrace', () {
      test('bar trace data rows have correct x, y, and name', () {
        final trace = BarTrace(x: ['A', 'B', 'C'], y: [3, 7, 2], name: 'bars');
        final result = buildChartData([trace]);
        expect(result.data, hasLength(3));
        expect(result.data[1]['x'], equals('B'));
        expect(result.data[1]['y'], equals(7));
        expect(result.data[1]['name'], equals('bars'));
      });

      test('bar trace with single marker broadcasts to all points', () {
        final m = Marker(size: 10);
        final trace = BarTrace(x: [1, 2, 3], y: [1, 2, 3], marker: [m]);
        final result = buildChartData([trace]);
        for (final row in result.data) {
          expect(row['marker'], same(m));
        }
      });
    });
  });
}
