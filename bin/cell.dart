import 'dart:collection';

import 'constants.dart';
import 'util.dart';

// ignore_for_file: unused_element

enum CellState {
  none(
    ulh: [" ．", "   "],
    ush: "‧ ",
    alh: [" . ", "   "],
    ash: ". ",
    styles: [Style.dim],
  ),
  ship(
    ulh: ["▃▃▃", "🮃🮃🮃"],
    ulv: ["🮈█▍", "🮈█▍"],
    ush: "🬋🬋",
    usv: "▊ ",
    alh: ["___", "‾‾‾"],
    alv: ["|| ", "|| "],
    ash: "==",
    asv: "||",
  ),
  hit(
    ulh: [" 🮦 ", " 🮧 "],
    ush: "Ｘ",
    alh: ["\\/ ", "/\\ "],
    ash: "X ",
    fg: Colors.red,
  ),
  miss(
    ulh: [" 🭯 ", " 🭭 "],
    ush: "◆ ",
    alh: [" v ", " ^ "],
    ash: "O ",
    fg: Colors.gray,
  );

  final List<String> ulh;
  final List<String>? ulv;
  final List<String> alh;
  final List<String>? alv;
  final String ush;
  final String? usv;
  final String ash;
  final String? asv;
  final Colors? fg;
  final Colors? bg;
  final List<Style>? styles;

  List<String> large({
    DisplayMode? displayMode,
    Orientation? orientation,
    bool plain = false,
  }) {
    displayMode ??= DisplayMode.current;
    orientation ??= Orientation.horizontal;

    var map = {
      DisplayMode.unicode: {
        Orientation.horizontal: ulh,
        Orientation.vertical: ulv ?? ulh,
      },
      DisplayMode.ascii: {
        Orientation.horizontal: alh,
        Orientation.vertical: alv ?? alh,
      },
    };

    var lines = map[displayMode]![orientation]!;
    if (plain) return lines;
    return lines.map((e) => e.fg(fg).bg(bg).styles(styles ?? [])).toList();
  }

  String small({
    DisplayMode? displayMode,
    Orientation? orientation,
    bool plain = false,
  }) {
    displayMode ??= DisplayMode.current;
    orientation ??= Orientation.horizontal;

    var map = {
      DisplayMode.unicode: {
        Orientation.horizontal: ush,
        Orientation.vertical: usv ?? ush,
      },
      DisplayMode.ascii: {
        Orientation.horizontal: ash,
        Orientation.vertical: asv ?? ash,
      },
    };

    var char = map[displayMode]![orientation]!;
    if (plain) return char;
    return char.fg(fg).bg(bg).styles(styles ?? []);
  }

  const CellState({
    // unicode
    required this.ulh,
    this.ulv,
    required this.ush,
    this.usv,
    // ascii
    required this.alh,
    this.alv,
    required this.ash,
    this.asv,
    // style
    this.fg,
    this.bg,
    this.styles,
  });
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

    const deltas = [-2, -1, 1, 2];

    // x
    for (int i = 0; i < deltas.length; i++) {
      var delta = deltas[i];
      var point = pos + Point(delta, 0);
      if (point.outOfBounds) continue;
      if (cells.at(point).isShip) horizontal++;
    }

    // y
    for (int i = 0; i < deltas.length; i++) {
      var delta = deltas[i];
      var point = pos + Point(0, delta);
      if (point.outOfBounds) continue;
      if (cells.at(point).isShip) vertical++;
    }

    if (horizontal >= vertical) {
      return Orientation.horizontal;
    } else {
      return Orientation.vertical;
    }
  }

  List<String> format(Orientation orientation) {
    return state.large(orientation: orientation);
  }

  String formatSmall(Orientation orientation) {
    return state.small(orientation: orientation);
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

  Cell at(Point pos) => pos.outOfBounds ? Cell(pos) : cells[pos.y][pos.x];
  Cell yx(int y, int x) =>
      Point(x, y).outOfBounds ? Cell.xy(x, y) : cells[y][x];
  Cell xy(int x, int y) =>
      Point(x, y).outOfBounds ? Cell.xy(x, y) : cells[y][x];
  List<Cell> y(int y) => Point(0, y).outOfBounds ? [] : cells[y];
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
