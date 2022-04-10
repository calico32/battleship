import 'constants.dart';

class Ship {
  Point pos;
  int length;
  Orientation orientation;

  Ship.xy(int x, int y, this.length, this.orientation) : pos = Point(x, y);
  Ship(this.pos, this.length, this.orientation);

  Ship move(Point delta) => Ship(pos + delta, length, orientation);
  Ship moveXY(int dx, int dy) =>
      Ship.xy(pos.x + dx, pos.y + dy, length, orientation);
  Ship rotate() => Ship(pos, length, orientation.rotated);

  List<Point> get points {
    var points = <Point>[];
    var pos = this.pos.clone();

    for (var i = 0; i < length; i++) {
      points.add(pos);
      if (orientation == Orientation.horizontal) {
        pos = pos += Point.right;
      } else {
        pos = pos += Point.down;
      }
    }

    return points;
  }

  bool get outsideBounds {
    for (var point in points) {
      if (point.outOfBounds) {
        return true;
      }
    }
    return false;
  }

  String pack() {
    return "${pos.x},${pos.y},$length,${orientation.index}";
  }

  factory Ship.unpack(String packed) {
    var parts = packed.split(",");
    return Ship.xy(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
      Orientation.values[int.parse(parts[3])],
    );
  }
}
