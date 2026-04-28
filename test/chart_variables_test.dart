import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphic/graphic.dart' as g;
import 'package:graphic_lite/src/display/marker.dart';
import 'package:graphic_lite/src/display/graphics/chart_variables.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Calls the x-accessor of [variable] with [row] and returns the result.
dynamic callX(
  g.Variable<Map<dynamic, dynamic>, dynamic> variable,
  Map<String, dynamic> row,
) => variable.accessor(row);

/// Calls the accessor of a variable in [vars] identified by [key].
dynamic callAccessor(
  Map<String, g.Variable<Map<dynamic, dynamic>, dynamic>> vars,
  String key,
  Map<String, dynamic> row,
) => vars[key]!.accessor(row);

// Standard domain used in most tests.
const (num, num) kDomainY = (-10.0, 110.0);

void main() {
  group('buildChartVariables', () {
    // --------------------------------------------------------- required keys
    group('returned map keys', () {
      test('contains all six expected keys', () {
        final data = [
          {'x': 1, 'y': 1.0, 'name': 'A', 'marker': null},
        ];
        final vars = buildChartVariables(data, domainY: kDomainY);
        expect(
          vars.keys,
          containsAll(['x', 'y', 'y_fill', 'name', 'text', 'marker.size']),
        );
      });

      test('returns exactly six keys', () {
        final data = [
          {'x': 1, 'y': 1.0, 'name': 'A', 'marker': null},
        ];
        final vars = buildChartVariables(data, domainY: kDomainY);
        expect(vars.length, equals(6));
      });

      test('works with an empty data list', () {
        final vars = buildChartVariables([], domainY: kDomainY);
        expect(
          vars.keys,
          containsAll(['x', 'y', 'y_fill', 'name', 'text', 'marker.size']),
        );
      });
    });

    // ----------------------------------------------- x-accessor dispatching
    group('x accessor — no domainX', () {
      test('int sample → accessor casts to int', () {
        final data = [
          {'x': 42, 'y': 1.0, 'name': 'A', 'marker': null},
        ];
        final vars = buildChartVariables(data, domainY: kDomainY);
        expect(callAccessor(vars, 'x', data.first), equals(42));
        expect(callAccessor(vars, 'x', data.first), isA<int>());
      });

      test('double sample → accessor casts to num', () {
        final data = [
          {'x': 3.14, 'y': 1.0, 'name': 'A', 'marker': null},
        ];
        final vars = buildChartVariables(data, domainY: kDomainY);
        expect(callAccessor(vars, 'x', data.first), closeTo(3.14, 1e-9));
      });

      test('DateTime sample → accessor casts to DateTime', () {
        final dt = DateTime(2024, 6, 1);
        final data = [
          {'x': dt, 'y': 1.0, 'name': 'A', 'marker': null},
        ];
        final vars = buildChartVariables(data, domainY: kDomainY);
        expect(callAccessor(vars, 'x', data.first), equals(dt));
        expect(callAccessor(vars, 'x', data.first), isA<DateTime>());
      });

      test('String sample → accessor casts to String', () {
        final data = [
          {'x': 'Q1', 'y': 1.0, 'name': 'A', 'marker': null},
        ];
        final vars = buildChartVariables(data, domainY: kDomainY);
        expect(callAccessor(vars, 'x', data.first), equals('Q1'));
        expect(callAccessor(vars, 'x', data.first), isA<String>());
      });
    });

    // ---------------------------------------- x with explicit domainX scale
    group('x accessor — with domainX', () {
      test('num x + domainX → accessor still returns correct value', () {
        final data = [
          {'x': 5.0, 'y': 1.0, 'name': 'A', 'marker': null},
        ];
        final vars = buildChartVariables(
          data,
          domainX: (0.0, 10.0),
          domainY: kDomainY,
        );
        expect(callAccessor(vars, 'x', data.first), closeTo(5.0, 1e-9));
      });

      test('int x + domainX → accessor returns int', () {
        final data = [
          {'x': 7, 'y': 1.0, 'name': 'A', 'marker': null},
        ];
        final vars = buildChartVariables(
          data,
          domainX: (0, 10),
          domainY: kDomainY,
        );
        expect(callAccessor(vars, 'x', data.first), equals(7));
      });

      test('DateTime x + domainX → accessor returns DateTime', () {
        final dt = DateTime(2024, 1, 15);
        final t0 = DateTime(2024, 1, 1);
        final t1 = DateTime(2024, 2, 1);
        final domainX = (
          t0.microsecondsSinceEpoch.toDouble(),
          t1.microsecondsSinceEpoch.toDouble(),
        );
        final data = [
          {'x': dt, 'y': 1.0, 'name': 'A', 'marker': null},
        ];
        final vars = buildChartVariables(
          data,
          domainX: domainX,
          domainY: kDomainY,
        );
        expect(callAccessor(vars, 'x', data.first), equals(dt));
      });

      test(
        'String x is NOT given an explicit scale even when domainX provided',
        () {
          // String x-axes are categorical; domainX is ignored.
          final data = [
            {'x': 'Jan', 'y': 1.0, 'name': 'A', 'marker': null},
          ];
          final vars = buildChartVariables(
            data,
            domainX: (0.0, 100.0),
            domainY: kDomainY,
          );
          expect(callAccessor(vars, 'x', data.first), equals('Jan'));
        },
      );
    });

    // ------------------------------------------------------- y / y_fill
    group('y accessor', () {
      test('int y → accessor returns int', () {
        final data = [
          {'x': 1, 'y': 99, 'name': 'A', 'marker': null},
        ];
        final vars = buildChartVariables(data, domainY: kDomainY);
        expect(callAccessor(vars, 'y', data.first), equals(99));
        expect(callAccessor(vars, 'y', data.first), isA<int>());
      });

      test('double y → accessor returns num', () {
        final data = [
          {'x': 1.0, 'y': 42.5, 'name': 'A', 'marker': null},
        ];
        final vars = buildChartVariables(data, domainY: kDomainY);
        expect(callAccessor(vars, 'y', data.first), closeTo(42.5, 1e-9));
      });
    });

    group('y_fill accessor', () {
      test('falls back to 0.0 when y_fill key is absent', () {
        final data = [
          {'x': 1, 'y': 10.0, 'name': 'A', 'marker': null},
        ];
        final vars = buildChartVariables(data, domainY: kDomainY);
        expect(callAccessor(vars, 'y_fill', data.first), closeTo(0.0, 1e-9));
      });

      test('returns the y_fill value when present', () {
        final data = [
          {'x': 1, 'y': 10.0, 'y_fill': 5.0, 'name': 'A', 'marker': null},
        ];
        final vars = buildChartVariables(data, domainY: kDomainY);
        expect(callAccessor(vars, 'y_fill', data.first), closeTo(5.0, 1e-9));
      });

      test('y and y_fill share the same scale instance', () {
        final data = [
          {'x': 1.0, 'y': 50.0, 'name': 'A', 'marker': null},
        ];
        final vars = buildChartVariables(data, domainY: kDomainY);
        // Both variables must reference the identical scale object.
        expect(vars['y']!.scale, same(vars['y_fill']!.scale));
      });
    });

    // ----------------------------------------------------------------- name
    group('name accessor', () {
      test('returns the name string', () {
        final row = {'x': 1, 'y': 1.0, 'name': 'my series', 'marker': null};
        final vars = buildChartVariables([row], domainY: kDomainY);
        expect(callAccessor(vars, 'name', row), equals('my series'));
      });
    });

    // ----------------------------------------------------------------- text
    group('text accessor', () {
      test('returns the text string when present', () {
        final row = {
          'x': 1,
          'y': 1.0,
          'name': 'A',
          'text': 'hello',
          'marker': null,
        };
        final vars = buildChartVariables([row], domainY: kDomainY);
        expect(callAccessor(vars, 'text', row), equals('hello'));
      });

      test('returns empty string when text key is absent', () {
        final row = {'x': 1, 'y': 1.0, 'name': 'A', 'marker': null};
        final vars = buildChartVariables([row], domainY: kDomainY);
        expect(callAccessor(vars, 'text', row), equals(''));
      });
    });

    // -------------------------------------------------------------- marker.size
    group('marker.size accessor', () {
      test('returns default 6.0 when marker is null', () {
        final row = {'x': 1, 'y': 1.0, 'name': 'A', 'marker': null};
        final vars = buildChartVariables([row], domainY: kDomainY);
        expect(callAccessor(vars, 'marker.size', row), closeTo(6.0, 1e-9));
      });

      test('returns the marker size when marker is set', () {
        final m = Marker(size: 12.0);
        final row = {'x': 1, 'y': 1.0, 'name': 'A', 'marker': m};
        final vars = buildChartVariables([row], domainY: kDomainY);
        expect(callAccessor(vars, 'marker.size', row), closeTo(12.0, 1e-9));
      });

      test('returns the correct size for a colored marker', () {
        final m = Marker(size: 8.0, color: Colors.red);
        final row = {'x': 1, 'y': 1.0, 'name': 'A', 'marker': m};
        final vars = buildChartVariables([row], domainY: kDomainY);
        expect(callAccessor(vars, 'marker.size', row), closeTo(8.0, 1e-9));
      });
    });

    // ---------------------------------------------------- domainY scale range
    group('domainY is applied to y scale', () {
      test('scale min/max match provided domainY', () {
        const domain = (-5.0, 55.0);
        final data = [
          {'x': 1.0, 'y': 25.0, 'name': 'A', 'marker': null},
        ];
        final vars = buildChartVariables(data, domainY: domain);
        final yScale = vars['y']!.scale as g.LinearScale;
        expect(yScale.min, closeTo(-5.0, 1e-9));
        expect(yScale.max, closeTo(55.0, 1e-9));
      });
    });
  });
}
