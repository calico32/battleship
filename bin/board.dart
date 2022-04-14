// textwrap, text wrapping and filling library, by the Python authors & Olzhas Suleimen (Dart port) (https://github.com/ykmnkmi)
// used in accordance with the MIT license
// https://pub.dev/packages/textwrap
// https://github.com/ykmnkmi/textwrap.dart
import 'package:textwrap/textwrap.dart';

import 'cell.dart';
import 'constants.dart';
import 'ship.dart';
import 'util.dart';

class Board {
  Cells cells;
  List<Ship> ships;
  Player owner;

  Board(this.owner, [CellState defaultState = CellState.none])
      : cells = Cells(),
        ships = [];

  static Board get host => Board(Player.host);
  static Board get guest => Board(Player.guest);

  void updateCells() {
    for (var row in cells) {
      for (var cell in row) {
        if (cell.state == CellState.hit || cell.state == CellState.miss) {
          continue;
        }
        cell.state = CellState.none;
      }
    }

    for (var ship in ships) {
      for (var point in ship.points) {
        if (cells.at(point).state == CellState.none) {
          cells.at(point).state = CellState.ship;
        }
      }
    }
  }

  List<Cell> operator [](int y) => cells.y(y);

  int addShip(Ship ship) {
    ships.add(ship);
    updateCells();
    return ships.length - 1;
  }

  String pack({bool showShips = true}) {
    var packedCells = [];
    for (var row in cells) {
      for (var cell in row) {
        packedCells.add(cell.pack(showShip: showShips));
      }
    }

    var packed = "$boardSize;${owner.index};${packedCells.join(" ")}";

    if (!showShips) {
      return packed;
    }

    return "$packed;${ships.map((s) => s.pack()).join(" ")}";
  }

  factory Board.unpack(String packed) {
    var parts = packed.split(";");
    var boardSize = int.parse(parts[0]);
    var owner = Player.values[int.parse(parts[1])];
    List<CellState> states = [];
    for (var stateIndex in parts[2].split(" ")) {
      states.add(CellState.values[int.parse(stateIndex)]);
    }

    List<List<Cell>> cells = [];
    for (var y = 0; y < boardSize; y++) {
      cells.add([]);
      for (var x = 0; x < boardSize; x++) {
        cells[y].add(Cell.xy(x, y, states[y * boardSize + x]));
      }
    }

    List<Ship> ships = [];
    if (parts.length == 4 && parts[3].isNotEmpty) {
      for (var ship in parts[3].split(" ")) {
        ships.add(Ship.unpack(ship));
      }
    }

    var board = Board(owner, CellState.none)
      ..cells = Cells.from(cells)
      ..ships = ships
      ..updateCells();

    return board;
  }

  Map<Point, Orientation> _getCellOrientations() {
    Map<Point, Orientation> result = {};
    for (var ship in ships) {
      for (var point in ship.points) {
        result[point] = ship.orientation;
      }
    }
    return result;
  }

  Map<Point, int> _getCellOwners() {
    Map<Point, int> result = {};
    for (var ship in ships) {
      for (var point in ship.points) {
        result[point] = ship.hashCode;
      }
    }
    return result;
  }

  bool isOccupied(Point point) {
    return cells.at(point).state != CellState.none;
  }

  Set<Point> getOverlaps() {
    var occupied = <Point>{};
    var overlaps = <Point>{};
    for (var ship in ships) {
      for (var point in ship.points) {
        if (occupied.contains(point)) {
          overlaps.add(point);
        } else {
          occupied.add(point);
        }
      }
    }
    return overlaps;
  }

  int get shipsRemaining {
    return ships
        .where(
          (s) => s.points.any((p) => cells.at(p).state == CellState.ship),
        )
        .length;
  }

  bool get isAllSunk {
    for (var row in cells) {
      for (var cell in row) {
        if (cell.state == CellState.ship) {
          return false;
        }
      }
    }

    return true;
  }

  String format({
    Point? selected,
    Ship? selctedShip,
    bool grayOutSelected = false,
  }) {
    selected ??= Point(-1, -1);

    var orientations = _getCellOrientations();
    var owners = _getCellOwners();
    var overlaps = getOverlaps();

    var selectedShipCells = selctedShip?.points ?? [];

    var result = DisplayMode.isUnicode
        ? "┏${"━━━━━" * boardSize}┓\n"
        : "+${"-----" * boardSize}+\n";

    for (var row in cells) {
      var topRow = DisplayMode.isUnicode ? "┃" : "|";
      var bottomRow = DisplayMode.isUnicode ? "┃" : "|";
      for (var cell in row) {
        var currentOwner = owners[cell.pos];
        var orientation = orientations[cell.pos] ?? cell.orientationIn(cells);

        Colors? color;
        if (selectedShipCells.contains(cell.pos)) color = Colors.cyan;
        if (overlaps.contains(cell.pos)) color = Colors.red;

        var lt = " ", lb = " ", rt = " ", rb = " ";

        var selector = DisplayMode.isUnicode ? "🭽🭼🭾🭿" : "┌└┐┘";

        if (cell.pos == selected) {
          var selColor = grayOutSelected ? Colors.gray : null;
          lt = selector[0].fg(selColor);
          lb = selector[1].fg(selColor);
          rt = selector[2].fg(selColor);
          rb = selector[3].fg(selColor);
        } else if (orientation == Orientation.horizontal &&
            cell.state == CellState.ship) {
          var left = cells.at(cell.pos + Point.left);
          if (left.state == CellState.ship &&
              owners[left.pos] == currentOwner) {
            var chars = CellState.ship.large();
            lt = chars[0].strip()[0].fg(color);
            lb = chars[1].strip()[0].fg(color);
          }
          var right = cells.at(cell.pos + Point.right);
          if (right.state == CellState.ship &&
              owners[right.pos] == currentOwner) {
            var chars = CellState.ship.large();
            rt = chars[0].strip()[0].fg(color);
            rb = chars[1].strip()[0].fg(color);
          }
        }

        if (selectedShipCells.isNotEmpty) {
          if (orientation == Orientation.horizontal) {
            if (cell.pos == selectedShipCells.first) {
              lt = selector[0].fg(color);
              lb = selector[1].fg(color);
            } else if (cell.pos == selectedShipCells.last) {
              rt = selector[2].fg(color);
              rb = selector[3].fg(color);
            }
          } else {
            if (cell.pos == selectedShipCells.first) {
              lt = selector[0].fg(color);
              rt = selector[2].fg(color);
            } else if (cell.pos == selectedShipCells.last) {
              lb = selector[1].fg(color);
              rb = selector[3].fg(color);
            }
          }
        }

        var parts = cell.format(orientation);
        var top = color != null ? parts[0].strip().fg(color) : parts[0];
        var bottom = color != null ? parts[1].strip().fg(color) : parts[1];
        topRow += "$lt$top$rt";
        bottomRow += "$lb$bottom$rb";
      }

      result += topRow + (DisplayMode.isUnicode ? "┃\n" : "|\n");
      result += bottomRow + (DisplayMode.isUnicode ? "┃\n" : "|\n");
    }

    result += DisplayMode.isUnicode
        ? "┗${"━━━━━" * boardSize}┛\n"
        : "+${"-----" * boardSize}+\n";

    return result;
  }

  String formatSmall() {
    var orientations = _getCellOrientations();

    var result = DisplayMode.isUnicode
        ? "┌─${"──" * boardSize}┐\n"
        : "+-${"--" * boardSize}+\n";

    for (var row in cells) {
      result += DisplayMode.isUnicode ? "│ " : "| ";
      for (var cell in row) {
        var orientation = orientations[cell.pos] ?? cell.orientationIn(cells);
        result += cell.formatSmall(orientation);
      }
      result += DisplayMode.isUnicode ? "│\n" : "|\n";
    }

    result += DisplayMode.isUnicode
        ? "└─${"──" * boardSize}┘\n"
        : "+-${"--" * boardSize}+\n";

    return result;
  }

  static String _addLabels(
    String combined, {
    bool largeIsOpponent = true,
    String? topLabel,
    String? bottomLabel,
  }) {
    var top = topLabel ?? (largeIsOpponent ? "Opponent's board" : "Your board");
    var bottom =
        bottomLabel ?? (largeIsOpponent ? "Your board" : "Opponent's board");

    var largeWidth = boardSize * 5 + 2;
    var smallWidth = boardSize * 2 + 2;

    var left = (largeWidth - top.length) ~/ 2;
    var right = largeWidth - top.length - left;

    var numbers =
        fullwidthNumbers.substring(0, boardSize).split("").join("   ");

    var header = "   ${" " * left}$top${" " * right}\n"
        "     $numbers\n";

    var lines = combined.split("\n");
    var width = lines[0].length;
    var formatted = <String>[];

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      var side = "  ";

      if (i >= 1 && i < 21 && i % 2 == 1) {
        side = fullwidthAlphabet[(i - 1) ~/ 2];
      }

      if (i >= 22 && i < 32) {
        side = " " + line.substring(0, 2);
        line = line.substring(2, width - 3) +
            " " +
            fullwidthAlphabet[i - 22] +
            line.substring(width - 1);
      }

      formatted.add("$side$line");
    }

    left = (smallWidth - bottom.length) ~/ 2;
    right = smallWidth - bottom.length - left;

    formatted[19] += "${" " * left}$bottom${" " * right}";
    formatted[20] += " ${fullwidthNumbers.substring(0, boardSize)}";

    return header + formatted.join("\n");
  }

  static String combine(
    Board large,
    Board small, {
    Point? selected,
    Ship? selectedShip,
    String? status,
    bool largeIsOpponent = true,
    String? topLabel,
    String? bottomLabel,
    bool grayOutSelected = false,
  }) {
    var largeStr = large.format(
      selected: selected,
      selctedShip: selectedShip,
      grayOutSelected: grayOutSelected,
    );
    var largeLineLength = largeStr.split("\n")[0].length;
    var smallLines = small.formatSmall().substring(1).split("\n");
    var smallStr = smallLines.join("\n" + " " * (largeLineLength - 1));

    var combined = largeStr.substring(0, largeStr.length - 2) + "╃" + smallStr;

    if (status == null || status == "") {
      return _addLabels(
        combined,
        largeIsOpponent: largeIsOpponent,
        topLabel: topLabel,
        bottomLabel: bottomLabel,
      );
    }

    var wrappedStatus = status
        .split('\n')
        .expand((e) => wrap(e, width: largeLineLength - 5))
        .toList();

    if (wrappedStatus.length > smallLines.length - 2) {
      throw ArgumentError.value(status, "status", "status too long");
    }

    var outputLines = combined.split("\n");
    var offset = largeStr.split("\n").length;
    for (var i = 0; i < wrappedStatus.length; i++) {
      var line = wrappedStatus[i];
      var target = offset + i;
      outputLines[target] = line.padRight(largeLineLength - 3) +
          outputLines[target].substring(largeLineLength - 3);
    }

    return _addLabels(
      outputLines.join("\n"),
      largeIsOpponent: largeIsOpponent,
      topLabel: topLabel,
      bottomLabel: bottomLabel,
    );
  }
}
