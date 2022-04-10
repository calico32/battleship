import 'dart:collection';

import 'package:tint/tint.dart';

import 'constants.dart';

enum CellState {
  none,
  ship,
  hit,
  miss,
}

class Cell {
  static String nameOfXY(int x, int y) {
    return alphabet[y] + x.toString();
  }

  static String nameOf(Point point) {
    return nameOfXY(point.x, point.y);
  }

  static bool isShipState(CellState state) {
    return state == CellState.ship || state == CellState.hit;
  }

  CellState state;
  Point pos;

  Cell.xy(int x, int y, [this.state = CellState.none]) : pos = Point(x, y);
  Cell(this.pos, [this.state = CellState.none]);

  String pack({bool showShip = false}) {
    if (!showShip && state == CellState.ship) {
      return CellState.none.index.toString();
    }
    return state.index.toString();
  }

  factory Cell.unpack(Point pos, String packed) {
    return Cell(pos, CellState.values[int.parse(packed)]);
  }

  factory Cell.unpackXY(int x, int y, String packed) {
    return Cell.xy(x, y, CellState.values[int.parse(packed)]);
  }

  bool get isShip => Cell.isShipState(state);
  String get name => Cell.nameOf(pos);

  Orientation orientationIn(Cells cells) {
    int horizontal = 0;
    int vertical = 0;

    for (int dx = -2; dx <= 2; dx++) {
      if (dx == 0) continue;
      var point = pos + Point(dx, 0);
      if (point.outOfBounds) continue;
      if (cells.at(point).isShip) horizontal++;
    }

    for (int dy = -2; dy <= 2; dy++) {
      if (dy == 0) continue;
      var point = pos + Point(0, dy);
      if (point.outOfBounds) continue;
      if (cells.at(point).isShip) horizontal++;
    }

    return horizontal >= vertical
        ? Orientation.horizontal
        : Orientation.vertical;
  }

  List<String> format(Orientation orientation) {
    switch (state) {
      case CellState.none:
        return [" ．".dim(), "   ".dim()];
      case CellState.ship:
        return orientation == Orientation.horizontal
            ? ["▃▃▃", "🮃🮃🮃"]
            : ["🮈█▍", "🮈█▍"];
      case CellState.hit:
        return [" 🮦 ".red(), " 🮧 ".red()];
      case CellState.miss:
        return [" 🭯 ".gray(), " 🭭 ".gray()];
    }
  }

  String formatSmall(Orientation orientation) {
    switch (state) {
      case CellState.none:
        return "‧ ".dim();
      case CellState.ship:
        return orientation == Orientation.horizontal ? "🬋🬋" : "▊ ";
      case CellState.hit:
        return "Ｘ".red();
      case CellState.miss:
        return "◆ ".gray();
    }
  }
}

class Cells with IterableMixin<List<Cell>> {
  List<List<Cell>> cells;

  Cells([CellState defaultState = CellState.none])
      : cells = List.generate(
          boardSize,
          (y) => List.generate(boardSize, (x) => Cell.xy(x, y, defaultState)),
        );

  Cells.from(this.cells);

  /// Returns the cell at the given coordinates.
  /// An out-of-bounds point will return a cell with the state [CellState.none].
  Cell at(Point pos) => pos.outOfBounds ? Cell(pos) : cells[pos.y][pos.x];

  /// Returns the cell at the given coordinates.
  /// An out-of-bounds point will return a cell with the state [CellState.none].
  Cell yx(int y, int x) =>
      Point(x, y).outOfBounds ? Cell.xy(x, y) : cells[y][x];

  /// Returns the cell at the given coordinates.
  /// An out-of-bounds point will return a cell with the state [CellState.none].
  Cell xy(int x, int y) =>
      Point(x, y).outOfBounds ? Cell.xy(x, y) : cells[y][x];

  /// Returns the row of cells at the given y coordinate.
  /// An out-of-bounds y coordinate will return an empty list.
  List<Cell> y(int y) => Point(0, y).outOfBounds ? [] : cells[y];

  /// Returns the column of cells at the given x coordinate.
  /// An out-of-bounds x coordinate will return an empty list.
  List<Cell> x(int x) => Point(x, 0).outOfBounds
      ? []
      : [for (var y = 0; y < boardSize; y++) cells[y][x]];

  String pack() {
    String result = "";
    for (var row in cells) {
      for (var cell in row) {
        result += cell.pack();
      }
    }
    return result;
  }

  @override
  Iterator<List<Cell>> get iterator => cells.iterator;
}
