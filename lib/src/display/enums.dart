enum AlignmentPlotly {
  start('start'),
  middle('middle'),
  end('end');

  const AlignmentPlotly(this._value);
  final String _value;

  static AlignmentPlotly parse(String value) {
    return switch (value) {
      'start' => AlignmentPlotly.start,
      'middle' => AlignmentPlotly.middle,
      'end' => AlignmentPlotly.end,
      _ => throw ArgumentError('Invalid value $value for PlotlyAlignment'),
    };
  }

  @override
  String toString() => _value;
}

enum AngleRef {
  previous,
  up;

  static AngleRef parse(String value) {
    return switch (value) {
      'previous' => AngleRef.previous,
      'up' => AngleRef.up,
      _ => throw ArgumentError('Invalid value $value for PlotlyAngleRef'),
    };
  }
}

enum AutoRange {
  yes('true'),
  no('false'),
  reversed('reversed'),
  min('min'),
  max('max'),
  minReversed('min reversed'),
  maxReversed('max reversed');

  const AutoRange(this._value);
  final String _value;

  static AutoRange parse(String value) {
    return switch (value) {
      'true' => AutoRange.yes,
      'false' => AutoRange.no,
      'reversed' => AutoRange.reversed,
      'min' => AutoRange.min,
      'max' => AutoRange.max,
      'min reversed' => AutoRange.minReversed,
      'max reversed' => AutoRange.maxReversed,
      _ => throw ArgumentError('Invalid value $value for PlotlyAutoRange'),
    };
  }

  @override
  String toString() => _value;
}

enum AxisType {
  // If "inferred", the axis type is automatically detected based on the input
  // data.
  inferred,
  linear,
  log,
  date,
  category;

  static AxisType parse(String value) {
    return switch (value) {
      'inferred' => AxisType.inferred,
      'linear' => AxisType.linear,
      'log' => AxisType.log,
      'date' => AxisType.date,
      'category' => AxisType.category,
      _ => throw ArgumentError('Invalid value $value for PlotlyAxisType'),
    };
  }
}

/// Determines a formatting rule for the tick exponents. For example, consider
/// the number 1,000,000,000. If "none", it appears as 1,000,000,000. If "e",
/// 1e+9. If "E", 1E+9. If "power", 1x10^9 (with 9 in a super script).
/// If "SI", 1G. If "B", 1B.
enum ExponentFormat {
  none('none'),
  e('e'),
  E('E'),
  power('power'),
  internationalSystemOfUnits('SI'),
  B('B');

  const ExponentFormat(this._value);
  final String _value;

  static ExponentFormat parse(String value) {
    return switch (value) {
      'none' => ExponentFormat.none,
      'e' => ExponentFormat.e,
      'E' => ExponentFormat.E,
      'power' => ExponentFormat.power,
      'SI' => ExponentFormat.internationalSystemOfUnits,
      'B' => ExponentFormat.B,
      _ => throw ArgumentError('Invalid value $value for PlotlyExponentFormat'),
    };
  }

  @override
  String toString() => _value;
}

enum Fill {
  none('none'),
  toZeroY('tozeroy'),
  toNextY('tonexty'),
  toSelf('toself');

  const Fill(this._value);
  final String _value;

  static Fill parse(String value) {
    return switch (value) {
      'none' => Fill.none,
      'tozeroy' => Fill.toZeroY,
      'tonexty' => Fill.toNextY,
      'toself' => Fill.toSelf,
      _ => throw ArgumentError('Invalid value $value for Fill enum'),
    };
  }

  @override
  String toString() => _value;
}

enum GroupNorm {
  none(''),
  fraction('fraction'),
  percent('percent');

  const GroupNorm(this._value);
  final String _value;

  static GroupNorm parse(String value) {
    return switch (value) {
      '' => GroupNorm.none,
      'fraction' => GroupNorm.fraction,
      'percent' => GroupNorm.percent,
      _ => throw ArgumentError('Invalid value $value for PlotlyGroupNorm'),
    };
  }

  @override
  String toString() => _value;
}

enum LengthMode {
  fraction,
  pixels;

  static LengthMode parse(String value) {
    return switch (value) {
      'fraction' => LengthMode.fraction,
      'pixels' => LengthMode.pixels,
      _ => throw ArgumentError('Invalid value $value for LenMode'),
    };
  }
}

/// Axis range mode.
/// If "normal", the range is computed in relation to the extrema of the input
/// data. If "tozero", the range extends to 0, regardless of the input data.
/// If "nonnegative", the range is non-negative, regardless of the input data.
/// Applies only to linear axes.
enum RangeMode {
  normal,
  toZero,
  nonNegative;

  static RangeMode parse(String value) {
    return switch (value) {
      'normal' => RangeMode.normal,
      'tozero' => RangeMode.toZero,
      'nonnegative' => RangeMode.nonNegative,
      _ => throw ArgumentError('Invalid value $value for Plotly RangeMode'),
    };
  }
}

/// Determines whether a x (y) axis is positioned at the "bottom" ("left") or
/// "top" ("right") of the plotting area.
enum Side {
  bottom,
  left,
  top,
  right;

  static Side parse(String value) {
    return switch (value) {
      'bottom' => Side.bottom,
      'left' => Side.left,
      'top' => Side.top,
      'right' => Side.right,
      _ => throw ArgumentError('Invalid value $value for PlotlySide'),
    };
  }
}

enum ShowExponent {
  all,
  first,
  last,
  none;

  static ShowExponent parse(String value) {
    return switch (value) {
      'all' => ShowExponent.all,
      'first' => ShowExponent.first,
      'last' => ShowExponent.last,
      'none' => ShowExponent.none,
      _ => throw ArgumentError('Invalid value $value for PlotlyShowExponent'),
    };
  }
}

enum TraceVisibility {
  on('true'),
  off('false'),
  legendOnly('legendonly');

  const TraceVisibility(this._value);
  final String _value;

  static TraceVisibility parse(String value) {
    return switch (value) {
      'true' => on,
      'false' => off,
      'legendonly' => legendOnly,
      _ => throw ArgumentError('Can\'t parse $value as a TraceVisibility'),
    };
  }

  @override
  String toString() => _value;
}
