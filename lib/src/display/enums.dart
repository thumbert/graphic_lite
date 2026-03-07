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

enum PlotlyLenMode {
  fraction,
  pixels;

  static PlotlyLenMode parse(String value) {
    return switch (value) {
      'fraction' => PlotlyLenMode.fraction,
      'pixels' => PlotlyLenMode.pixels,
      _ => throw ArgumentError('Invalid value $value for PlotlyLenMode'),
    };
  }
}

enum PlotlyShowExponent {
  all,
  first,
  last,
  none;

  static PlotlyShowExponent parse(String value) {
    return switch (value) {
      'all' => PlotlyShowExponent.all,
      'first' => PlotlyShowExponent.first,
      'last' => PlotlyShowExponent.last,
      'none' => PlotlyShowExponent.none,
      _ => throw ArgumentError('Invalid value $value for PlotlyShowExponent'),
    };
  }
}
