import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphic_lite/graphic_lite.dart';

enum GroupClick { toggleItem, toggleGroup }

enum ItemClick { toggle, toggleOthers, disabled }

enum ItemDoubleClick { toggle, toggleOthers, disabled }

enum ItemSizing { trace, constant }

// enum Side { top, left, topLeft, topCenter, topRight }

enum TraceOrder { normal, reversed, grouped, groupedReversed }

enum VerticalAlignment { top, middle, bottom }

enum XAnchor { auto, left, center, right }

/// Coordinate system for x and y position. [container] spans the entire
/// `width` and `height` of the plot. [paper] refers to the width and height
/// of the plotting area only.
enum Ref { container, paper }

enum YAnchor { auto, top, middle, bottom }

/// See https://plotly.com/javascript/reference/layout/#layout-legend
class Legend {
  Legend({
    Side? side,
    MainAxisAlignment? mainAxisAlignment,
    CrossAxisAlignment? crossAxisAlignment,
  }) {
    if (side != null) {
      this.side = side;
    }
    if (mainAxisAlignment != null) {
      this.mainAxisAlignment = mainAxisAlignment;
    }
    if (crossAxisAlignment != null) {
      this.crossAxisAlignment = crossAxisAlignment;
    }
  }
  // LegendOrientation orientation = LegendOrientation.vertical;
  Side side = Side.right;
  MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start;
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start;

  Color? backgroundColor;
  Color? borderColor;
  double? borderWidth;
  double? entryWidth;
  // Font? font;

  LegendTitle? title;

  /// Sets the indentation (in px) of the legend entries.
  double indentation = 0.0;

  /// Sets the width (in px) of the legend item symbols (the part other than
  /// the title.text).
  double get itemWidth => max(_itemWidth, 30.0);
  set itemWidth(double value) => _itemWidth = value;
  double _itemWidth = 30.0;

  /// Sets the amount of vertical space (in px) between legend groups.
  double traceGroupGap = 10.0;

  /// Determines the order at which the legend items are displayed. If "normal",
  /// the items are displayed top-to-bottom in the same order as the input data.
  /// If "reversed", the items are displayed in the opposite order as "normal".
  /// If "grouped", the items are displayed in groups (when a trace
  /// `legendGroup` is provided).  If "groupedReversed", the items are
  /// displayed in the opposite order as "grouped".
  TraceOrder traceOrder = TraceOrder.normal;

  /// Sets the vertical alignment of the symbols with respect to their
  /// associated text.
  VerticalAlignment verticalAlignment = VerticalAlignment.middle;

  /// Determines whether or not the legend is visible.
  bool visible = true;

  /// Sets the x position with respect to `xref` (in normalized coordinates) of
  /// the legend. When `xref` is "paper", defaults to "1.02" for vertical
  /// legends and defaults to "0" for horizontal legends. When `xref` is
  /// "container", defaults to "1" for vertical legends and defaults to "0"
  /// for horizontal legends. Must be between "0" and "1" if `xref` is
  /// "container". and between "-2" and "3" if `xref` is "paper".
  double? x;

  /// Sets the legend's horizontal position anchor. This anchor binds the `x`
  /// position to the "left", "center" or "right" of the legend. Value "auto"
  /// anchors legends to the right for `x` values greater than or equal to 2/3,
  /// anchors legends to the left for `x` values less than or equal to 1/3 and
  /// anchors legends with respect to their center otherwise.
  XAnchor xAnchor = XAnchor.left;

  /// Sets the container `x` refers to. "container" spans the entire `width`
  /// of the plot. "paper" refers to the width of the plotting area only.
  Ref xRef = Ref.paper;

  /// Sets the y position with respect to `yref` (in normalized coordinates)
  /// of the legend. When `yref` is "paper", defaults to "1" for vertical
  /// legends, defaults to "-0.1" for horizontal legends on graphs w/o range
  /// sliders and defaults to "1.1" for horizontal legends on graph with one
  /// or multiple range sliders. When `yref` is "container", defaults to "1".
  /// Must be between "0" and "1" if `yref` is "container" and between "-2"
  /// and "3" if `yref` is "paper".
  double? y;

  /// Sets the container `y` refers to. "container" spans the entire `height`
  /// of the plot. "paper" refers to the height of the plotting area only.
  Ref yRef = Ref.paper;

  static Legend fromJson(Map<String, dynamic> x) {
    var legend = Legend();
    // if (x.containsKey('orientation')) {
    //   legend.orientation = LegendOrientation.parse(x['orientation']);
    // }
    return legend;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      // if (orientation != LegendOrientation.vertical)
      //   'orientation': orientation.toString(),
    };
  }
}

class LegendTitle {
  String? text;
  // Font? font;

  /// Determines the location of legend's title with respect to the legend
  /// items. Defaulted to "top" with `orientation` is "h". Defaulted to "left"
  /// with `orientation` is "v". The "top left" options could be used to expand
  /// top center and top right are for horizontal alignment legend area in both
  /// x and y sides.
  Side? side;
}

class LegendGroupTitle {
  PlotlyFont? font;
  String text = '';

  static LegendGroupTitle fromJson(Map<String, dynamic> x) {
    var out = LegendGroupTitle();
    if (x.containsKey('font')) out.font = PlotlyFont.fromJson(x['font']);
    if (x.containsKey('text')) out.text = x['text'];
    return out;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (font != null) 'font': font!.toJson(),
      if (text != '') 'text': text,
    };
  }
}
