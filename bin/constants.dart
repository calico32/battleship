import 'cell.dart';

const boardSize = 10;
const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
const fullwidthAlphabet = "ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ";
const numbers = "0123456789";
const fullwidthNumbers = "０１２３４５６７８９";

const arrowUp = "\x1b[A";
const arrowDown = "\x1b[B";
const arrowRight = "\x1b[C";
const arrowLeft = "\x1b[D";

const msg = "\t\t\t";
final battleshipLogo = r"""
   ___  ___ ______________   __________ _________
  / _ )/ _ /_  __/_  __/ /  / __/ __/ // /  _/ _ \
 / _  / __ |/ /   / / / /__/ _/_\ \/ _  // // ___/
/____/_/ |_/_/   /_/ /____/___/___/_//_/___/_/
"""
    .splitMapJoin('\n', onNonMatch: (line) => line.padRight(60).padLeft(70));

enum UIState {
  title,
  hostEntry,
  hostWaiting,
  guestEntry,
  guestWaiting,
  prepare,
  playing,
  gameOver,
}

enum ClientMessageType {
  ready,
  guess,
}

enum ServerMessageType {
  init,
  prepare,
  opponentReady,
  play,
  turn,
  guessResult,
  gameFinished,
}

enum Player {
  host,
  guest,
}

enum Orientation {
  horizontal,
  vertical,
}

extension OrientationRotated on Orientation {
  Orientation get rotated => this == Orientation.horizontal
      ? Orientation.vertical
      : Orientation.horizontal;
}

class Point {
  int x;
  int y;

  Point(this.x, this.y);
  Point.only({this.x = 0, this.y = 0});
  static Point get zero => Point(0, 0);
  static Point get left => Point(-1, 0);
  static Point get right => Point(1, 0);
  static Point get up => Point(0, -1);
  static Point get down => Point(0, 1);

  @override
  int get hashCode => Object.hash(x, y);

  bool get outOfBounds => x < 0 || x >= boardSize || y < 0 || y >= boardSize;
  bool get nonzero => x != 0 || y != 0;

  @override
  bool operator ==(other) {
    return other is Point && other.x == x && other.y == y;
  }

  Point operator +(other) {
    if (other is Point) {
      return Point(x + other.x, y + other.y);
    } else if (other is int) {
      return Point(x + other, y + other);
    }

    throw ArgumentError.value(other);
  }

  Point operator -(other) {
    if (other is Point) {
      return Point(x - other.x, y - other.y);
    } else if (other is int) {
      return Point(x - other, y - other);
    }

    throw ArgumentError.value(other);
  }

  Point operator *(other) {
    if (other is Point) {
      return Point(x * other.x, y * other.y);
    } else if (other is int) {
      return Point(x * other, y * other);
    }

    throw ArgumentError.value(other);
  }

  Point operator ~/(other) {
    if (other is Point) {
      return Point(x ~/ other.x, y ~/ other.y);
    } else if (other is int) {
      return Point(x ~/ other, y ~/ other);
    }

    throw ArgumentError.value(other);
  }

  Point operator /(other) {
    return this ~/ other;
  }

  @override
  String toString() {
    return Cell.nameOf(this);
  }

  Point clone() {
    return Point(x, y);
  }
}
