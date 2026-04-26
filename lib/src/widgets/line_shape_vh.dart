import 'package:flutter/painting.dart';
import 'package:graphic/graphic.dart' as g;

/// A line shape for a vertical followed by horizontal segments.
class LineShapeVh extends g.LineShape {
  /// Creates a line shape for a vertical followed by a horizontal segment.
  LineShapeVh({this.dash});

  /// The circular array of dash offsets and lengths.
  ///
  /// For example, the array `[5, 10]` would result in dashes 5 pixels long
  /// followed by blank spaces 10 pixels long.  The array `[5, 10, 5]` would
  /// result in a 5 pixel dash, a 10 pixel gap, a 5 pixel dash, a 5 pixel gap,
  /// a 10 pixel dash, etc.
  final List<double>? dash;

  @override
  bool equalTo(Object other) =>
      other is LineShapeVh && deepCollectionEquals(dash, other.dash);

  @override
  List<g.MarkElement> drawGroupPrimitives(
    List<g.Attributes> group,
    g.CoordConv coord,
    Offset origin,
  ) {
    assert(!(coord is g.PolarCoordConv && coord.transposed));

    final contours = <List<Offset>>[];

    var currentContour = <Offset>[];
    for (var item in group) {
      assert(item.shape is LineShapeVh);

      if (item.position.last.dy.isFinite) {
        final point = coord.convert(item.position.last);
        currentContour.add(point);
      } else if (currentContour.isNotEmpty) {
        contours.add(currentContour);
        currentContour = [];
      }
    }
    if (currentContour.isNotEmpty) {
      contours.add(currentContour);
    }

    final primitives = <g.MarkElement>[];

    final represent = group.first;
    final strokeWidth = represent.size ?? defaultSize;
    final style = g.getPaintStyle(
      represent,
      true,
      strokeWidth,
      coord.region,
      dash,
    );

    for (var contour in contours) {
      primitives.add(
        g.PolylineElement(points: getSteppedPointsVh(contour), style: style),
      );
    }

    return primitives;
  }

  @override
  List<g.MarkElement> drawGroupLabels(
    List<g.Attributes> group,
    g.CoordConv coord,
    Offset origin,
  ) => drawLineLabels(group, coord, origin);
}

/// Produces a stepped polyline.
List<Offset> getSteppedPointsVh(List<Offset> points) {
  final rst = <Offset>[];

  if (points.isNotEmpty) {
    rst.add(points[0]);
  }

  for (var i = 1; i < points.length; i++) {
    rst.add(Offset(points[i - 1].dx, points[i].dy));
    rst.add(points[i]);
  }

  return rst;
}

List<g.MarkElement> drawLineLabels(
  List<g.Attributes> group,
  g.CoordConv coord,
  Offset origin,
) {
  final labels = <g.Attributes, Offset>{};
  for (var item in group) {
    final position = item.position;
    if (position.every((point) => point.dy.isFinite)) {
      final end = coord.convert(position.last);
      labels[item] = end;
    }
  }
  final labelElements = <g.MarkElement>[];
  for (var item in labels.keys) {
    if (item.label != null && item.label!.haveText) {
      labelElements.add(
        g.LabelElement(
          text: item.label!.text!,
          anchor: labels[item]!,
          defaultAlign: coord.transposed
              ? Alignment.centerRight
              : Alignment.topCenter,
          style: item.label!.style,
        ),
      );
    }
  }
  return labelElements;
}

bool deepCollectionEquals<T>(T? a, T? b) {
  if (a == b) {
    return true;
  }
  if (a == null || b == null) {
    return false;
  }

  // Since the equality is for specification literals, sets are also treated ordered.
  // Thus equal Sets should have same order. This avoids collection item duplication
  // in sets: {{1, 1}, {1, 1}} and {{1, 1}, {1, 2}}.
  if (a is Iterable) {
    b as Iterable;
    if (a.length != b.length) {
      return false;
    }
    final aList = a.toList();
    final bList = b.toList();
    for (var i = 0; i < a.length; i++) {
      if (!deepCollectionEquals(aList[i], bList[i])) {
        return false;
      }
    }
    return true;
  }
  if (a is Map) {
    b as Map;
    if (a.length != b.length) {
      return false;
    }
    for (var key in a.keys) {
      if (!deepCollectionEquals(a[key], b[key])) {
        return false;
      }
    }
    return true;
  }
  return false;
}
