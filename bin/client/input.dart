import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../cell.dart';
import '../constants.dart';
import '../game.dart';
import '../ship.dart';
import '../util.dart';
import 'draw.dart';

final validInputChars = RegExp(r'[ A-Za-z0-9_-]');

mixin ClientInputHandler on ClientUI {
  Future<bool> handleInput(String key) async {
    final data = currentData;
    switch (state) {
      case UIState.title:
        if (handleMenuNav(data, key, 3)) {
          return false;
        }

        if (key == "\r" || key == "\n") {
          switch (data["selected"]) {
            case 0:
              state = UIState.hostEntry;
              break;
            case 1:
              state = UIState.guestEntry;
              break;
            case 2:
            default:
              return true;
          }
        }

        break;
      case UIState.hostEntry:
        if (handleMenuNav(data, key, 3)) {
          return false;
        }

        if (key == "\x7f") {
          if (data["selected"] == 0) {
            data["name"] = data["name"]!
                .substring(0, max(0, (data["name"]!.length as int) - 1));
          }
          return false;
        }

        if (key == "\r" || key == "\n") {
          if (data["selected"] == 1) {
            selfName = data["name"]!;
            state = UIState.hostWaiting;
            gameId = await createRoom();
            draw();
            socket = await joinRoom();
            listen();
            draw();
          } else if (data["selected"] == 2) {
            state = UIState.title;
          }
          return false;
        }

        if (validInputChars.hasMatch(key)) {
          if (data["selected"] == 0 && data["name"].length < 30) {
            data["name"] += key;
          }

          return false;
        }
        break;

      case UIState.guestEntry:
        if (handleMenuNav(data, key, 4)) {
          return false;
        }

        if (key == "\x7f") {
          if (data["selected"] == 0) {
            data["name"] = data["name"]!
                .substring(0, max(0, (data["name"]!.length as int) - 1));
          } else if (data["selected"] == 1) {
            data["id"] = data["id"]!
                .substring(0, max(0, (data["id"]!.length as int) - 1));
          }
          return false;
        }

        if (key == "\r" || key == "\n") {
          data["status"] = "";
          if (data["selected"] == 2) {
            var gameState = await getGameState(data["id"]);
            if (gameState == GameState.waiting) {
              state = UIState.guestWaiting;
              gameId = data["id"];
              selfName = data["name"];
              draw();
              socket = await joinRoom();
              listen();
              draw();
            } else if (gameState == GameState.none) {
              data["status"] = "Game does not exist.";
            } else {
              data["status"] = "That game has already started.";
            }
          } else if (data["selected"] == 3) {
            state = UIState.title;
          }
          return false;
        }

        if (validInputChars.hasMatch(key)) {
          if (data["selected"] == 0 && data["name"].length < 30) {
            data["name"] += key;
          } else if (data["selected"] == 1 && data["id"].length < 30) {
            data["id"] += key;
          }

          return false;
        }
        break;
      case UIState.hostWaiting:
      case UIState.guestWaiting:
        if (key == "\r" || key == "\n") {
          state = UIState.title;
          gameId = null;
          selfName = null;
          socket?.close(WebSocketStatus.normalClosure);
          socket = null;
          return false;
        }
        break;
      case UIState.prepare:
        if (data["self_ready"] == true) {
          // we already sent the ready signal, can't modify ships anymore
          return false;
        }
        assert(selfBoard != null);
        assert(currentShip != null);
        var board = selfBoard!;
        var ship = currentShip!;

        if (key == "[" || key == "]") {
          var shipChange = key == "[" ? -1 : 1;
          var currentIndex = board.ships.indexOf(ship);
          var newIndex = (currentIndex + shipChange) % board.ships.length;
          ship = currentShip = board.ships[newIndex];
          return false;
        }

        var delta = Point.zero;
        var rotate = false;

        if (key == arrowLeft) delta.x -= 1;
        if (key == arrowRight) delta.x += 1;
        if (key == arrowUp) delta.y -= 1;
        if (key == arrowDown) delta.y += 1;
        if (key == "r") rotate = true;
        if (key == "\r" || key == "\n") {
          if (shipsToPlace.isEmpty) {
            if (board.getOverlaps().isEmpty) {
              data["self_ready"] = true;
              socket!.add(json.encode({
                "type": ClientMessageType.ready.index,
                "board": board.pack(),
              }));
            }

            // overlapping ships, do nothing
            return false;
          }

          shipsToPlace.removeAt(0);
          if (shipsToPlace.isNotEmpty) {
            ship = currentShip =
                Ship(Point.zero, shipsToPlace[0], Orientation.horizontal);
            board.addShip(ship);
          }

          return false;
        }

        if (delta.nonzero) {
          var next = ship.move(delta);
          if (next.outsideBounds) delta = Point.zero;
        }

        if (rotate) {
          delta = Point.zero;
          var next = ship.rotate();

          while (next.move(delta).outsideBounds) {
            var points = next.move(delta).points;
            var xRange = points.map((p) => p.x);
            var yRange = points.map((p) => p.y);

            var minX = xRange.reduce(min);
            var maxX = xRange.reduce(max);
            var minY = yRange.reduce(min);
            var maxY = yRange.reduce(max);

            var currentDelta = Point.zero;

            if (minX < 0) currentDelta.x = -minX;
            if (maxX >= boardSize) currentDelta.x = boardSize - maxX - 1;
            if (minY < 0) currentDelta.y = -minY;
            if (maxY >= boardSize) currentDelta.y = boardSize - maxY - 1;

            if (!currentDelta.nonzero) {
              throw StateError(
                  "Couldn't find a valid position for the ship ${ship.pack()}");
            }

            delta += currentDelta;
          }

          ship.orientation = next.orientation;
        }

        if (delta.nonzero || rotate) {
          ship.pos += delta;
          board.updateCells();
          return false;
        }

        break;
      case UIState.playing:
        if (turn != selfOwner || data["guess_sent"] == true) {
          return false;
        }

        var delta = Point.zero;
        if (key == arrowLeft) delta.x -= 1;
        if (key == arrowRight) delta.x += 1;
        if (key == arrowUp) delta.y -= 1;
        if (key == arrowDown) delta.y += 1;

        if (delta.nonzero && !(currentPoint + delta).outOfBounds) {
          currentPoint += delta;
        }

        if (key == "\r" || key == "\n") {
          if (currentPoint.outOfBounds) {
            return false;
          }

          var cell = opponentBoard!.cells.at(currentPoint);
          if (cell.state == CellState.none) {
            socket!.add(json.encode({
              "type": ClientMessageType.guess.index,
              "row": currentPoint.y,
              "col": currentPoint.x,
            }));
            data["guess_sent"] = true;
            return false;
          }
        }

        break;
      case UIState.gameOver:
        // do nothing
        break;
    }
    return false;
  }
}
