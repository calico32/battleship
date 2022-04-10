import 'board.dart';
import 'cell.dart';
import 'constants.dart';
import 'ship.dart';

void main() {
  var board = Board(Player.guest);

  board.addShip(Ship.xy(0, 0, 5, Orientation.vertical));
  board.addShip(Ship.xy(2, 0, 4, Orientation.horizontal));
  board.addShip(Ship.xy(2, 2, 3, Orientation.vertical));
  board.addShip(Ship.xy(4, 2, 3, Orientation.horizontal));
  board.addShip(Ship.xy(4, 4, 2, Orientation.vertical));

  var cells = board.cells;
  var c = cells.xy;

  c(0, 0).state = CellState.miss;
  c(2, 0).state = CellState.miss;
  c(2, 2).state = CellState.hit;
  c(4, 2).state = CellState.hit;

  print(Board.combine(board, board));
}
