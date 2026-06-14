/// "coupled" gives one x axis per column and one y axis per row. "independent" 
/// uses a new xy pair for each cell, left-to-right across each row then 
/// iterating rows according to [rowOrder].
enum GridPattern { independent, coupled }

/// Is the first row the top or the bottom? Note that columns are always 
/// enumerated from left to right.
enum GridRowOrder { topToBottom, bottomToTop }

class Grid {
  Grid({
    this.columns = 1,
    this.rows = 1,
    this.pattern = GridPattern.independent,
    this.rowOrder = GridRowOrder.topToBottom,
    num? xGap,
    num? yGap,
  }) {
    this.xGap =
        xGap ??
        switch (pattern) {
          GridPattern.coupled => 0.1,
          GridPattern.independent => 0.2,
        };
    this.yGap =
        yGap ??
        switch (pattern) {
          GridPattern.coupled => 0.1,
          GridPattern.independent => 0.3,
        };
  }

  /// The number of columns in the grid. If you provide a 2D `subplots` array,
  /// the length of its longest row is used as the default. If you give an
  /// `xaxes` array, its length is used as the default. But it's also possible
  /// to have a different length, if you want to leave a row at the end for
  /// non-cartesian subplots.
  ///
  /// An integer greater than or equal to 1.
  int columns;

  /// The number of rows in the grid. If you provide a 2D `subplots` array or
  /// a `yaxes` array, its length is used as the default. But it's also
  /// possible to have a different length, if you want to leave a row at the
  /// end for non-cartesian subplots.
  ///
  /// An integer greater than or equal to 1.
  int rows;

  /// If no `subplots`, `xaxes`, or `yaxes` are given but we do have `rows`
  /// and `columns`, we can generate defaults using consecutive axis IDs, in
  /// two ways: "coupled" gives one x axis per column and one y axis per row.
  /// "independent" uses a new xy pair for each cell, left-to-right across each
  /// row then iterating rows according to `rowOrder`.
  GridPattern pattern;

  /// Is the first row the top or the bottom? Note that columns are always
  /// enumerated from left to right.
  GridRowOrder rowOrder;

  /// Horizontal space between grid cells, expressed as a fraction of the total
  /// width available to one cell. Defaults to 0.1 for coupled-axes grids and
  /// 0.2 for independent grids.
  late num xGap;

  /// Vertical space between grid cells, expressed as a fraction of the total
  /// height available to one cell. Defaults to 0.1 for coupled-axes grids and
  /// 0.3 for independent grids.
  late num yGap;
}
