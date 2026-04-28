import 'package:graphic/graphic.dart' as g;
import 'package:graphic_lite/src/display/marker.dart';

/// Builds the `variables` map expected by package `graphic`'s [g.Chart].
///
/// [data] is the flat list produced by [buildChartData].
/// [domainX] — when provided and x is not a [String], an explicit scale is
///   applied to the x-axis (e.g. after a drag-select zoom).
/// [domainY] — the y-axis domain used to build a shared scale for `y` and
///   `y_fill` (those two must reference the identical scale object to satisfy
///   the graphic library's `PositionEncoderOp` assertion).
///
/// x/y types are inferred from the first element of [data]; an empty list
/// returns a map with accessor-only (no-scale) variables.
Map<String, g.Variable<Map<dynamic, dynamic>, dynamic>> buildChartVariables(
  List<Map<String, dynamic>> data, {
  (num, num)? domainX,
  required (num, num) domainY,
}) {
  final out = <String, g.Variable<Map<dynamic, dynamic>, dynamic>>{};

  final sampleX = data.isNotEmpty ? data.first['x'] : null;
  final sampleY = data.isNotEmpty ? data.first['y'] : null;

  // ── x variable ────────────────────────────────────────────────────────────
  if (domainX != null && sampleX is! String) {
    final xScale = sampleX is DateTime
        ? g.TimeScale(
            min: DateTime.fromMicrosecondsSinceEpoch(domainX.$1.round()),
            max: DateTime.fromMicrosecondsSinceEpoch(domainX.$2.round()),
          )
        : g.LinearScale(min: domainX.$1, max: domainX.$2);
    out['x'] = switch (sampleX) {
      DateTime() => g.Variable(
        accessor: (Map map) => map['x'] as DateTime,
        scale: xScale as g.Scale<DateTime, num>,
      ),
      int() => g.Variable(
        accessor: (Map map) => map['x'] as int,
        scale: xScale as g.Scale<num, num>,
      ),
      _ => g.Variable(
        accessor: (Map map) => map['x'] as num,
        scale: xScale as g.Scale<num, num>,
      ),
    };
  } else {
    out['x'] = switch (sampleX) {
      DateTime() => g.Variable(accessor: (Map map) => map['x'] as DateTime),
      int() => g.Variable(accessor: (Map map) => map['x'] as int),
      String() => g.Variable(accessor: (Map map) => map['x'] as String),
      _ => g.Variable(accessor: (Map map) => map['x'] as num),
    };
  }

  // ── y / y_fill variables — must share the same scale instance ─────────────
  final yScale = g.LinearScale(min: domainY.$1, max: domainY.$2);
  out['y'] = switch (sampleY) {
    int() => g.Variable(
      accessor: (Map map) => map['y'] as int,
      scale: yScale as g.Scale<num, num>,
    ),
    _ => g.Variable(
      accessor: (Map map) => map['y'] as num,
      scale: yScale as g.Scale<num, num>,
    ),
  };
  out['y_fill'] = g.Variable(
    accessor: (Map map) => (map['y_fill'] ?? 0.0) as num,
    scale: yScale, // identical instance — required by graphic
  );

  // ── auxiliary variables ───────────────────────────────────────────────────
  out['name'] = g.Variable(accessor: (Map e) => e['name'] as String);
  out['text'] = g.Variable(accessor: (Map e) => (e['text'] ?? '') as String);
  out['marker.size'] = g.Variable(
    accessor: (Map e) => (e['marker'] as Marker?)?.size.toDouble() ?? 6.0,
  );

  return out;
}
