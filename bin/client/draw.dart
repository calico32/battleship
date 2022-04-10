import 'dart:io';

import '../board.dart';
import '../cell.dart';
import '../constants.dart';
import '../util.dart';
import 'state.dart';

mixin ClientUI on ClientState {
  String currentLogo = battleshipLogo;
  int logoFrame = 19;
  bool shouldAnimate = true;

  int lastTermSize = 0;

  Future<void> animateLogo() async {
    while (shouldAnimate) {
      final lines = battleshipLogo.split("\n");
      if (logoFrame < 4) {
        lines[logoFrame] = lines[logoFrame].cyan();
        currentLogo = lines.join("\n");
        moveCursor(0, 0);
        draw();
      } else if (logoFrame == 4) {
        currentLogo = lines.join("\n");
        moveCursor(0, 0);
        draw();
      }
      logoFrame = (logoFrame + 1) % 20;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    currentLogo = battleshipLogo;
    logoFrame = 19;
  }

  String status = "";

  @override
  Future<void> update() async => draw();

  void updateStatus() {
    final data = currentData;
    switch (state) {
      case UIState.title:
        int selected = data["selected"];
        final options = [
          "Create room",
          "Join room",
          "Quit",
        ];
        status = formatMenu(options, selected);
        break;
      case UIState.hostEntry:
        int selected = data["selected"];
        final options = [
          "Name: ${data["name"]}",
          "Create",
          "Cancel",
        ];
        if (selected == 0) options[selected] += "_";
        status = formatMenu(options, selected);
        break;
      case UIState.guestEntry:
        int selected = data["selected"];
        final options = [
          "Name: ${data["name"]}",
          "Game ID: ${data["id"]}",
          "Join",
          "Cancel",
        ];
        status = data["status"] ?? "";
        if (selected == 0 || selected == 1) options[selected] += "_";
        status = formatMenu(options, selected);
        break;
      case UIState.hostWaiting:
      case UIState.guestWaiting:
        status = "Game ID: $gameId\n\n";
        if (socket == null || selfName == null || selfOwner == null) {
          status += "Connecting to game server...";
        } else {
          status += "Name: $selfName\n"
              "You are this room's ${selfOwner!.name.toUpperCase()}\n\n"
              "Waiting for ${state == UIState.hostWaiting ? "opponent" : "server"}...";
        }
        status += "\n\n> Cancel";
        break;
      case UIState.prepare:
        status = "Pregame\n\n";

        if (data["opponent_ready"] == true) {
          status += "Your opponent is ready!\n";
        }

        if (data["self_ready"] == true) {
          if (data["opponent_ready"] == true) {
            status += "You are ready! Waiting for server...";
          } else {
            status += "You are ready! Waiting for opponent...";
          }
          return;
        }

        status += "Place your ships!\n\n"
            "Arrow keys to move, R to rotate, [ and ] to change selection";
        if (shipsToPlace.isNotEmpty) {
          status += ". Enter to place.";
        } else {
          status +=
              ".\n\nPress Enter to lock in your ships and mark your board as ready.";
        }
        var overlaps = selfBoard!.getOverlaps();
        if (overlaps.isNotEmpty) {
          status += "\n\n"
              "You have overlapping ships at ${overlaps.join(' ')}!\n"
              "Remove them before continuing.";
        }
        break;
      case UIState.playing:
        if (data["guess_result"] != "") {
          var guesserName =
              data["guess_turn"] == selfOwner ? selfName : opponentName;
          var cellName = Cell.nameOfXY(data["guess_col"], data["guess_row"]);
          status =
              "$guesserName guessed $cellName and it was a ${data["guess_result"].toString().toUpperCase()}!";
        } else if (turn == selfOwner) {
          status = "It's your turn!\n\n";
          if (data["guess_sent"] == true) {
            status += "Waiting for server...";
          } else {
            status += "Arrow keys to select a cell";
            if (opponentBoard!.cells.at(currentPoint).state != CellState.none) {
              status += " (You already fired here.)";
            } else {
              status += ". Enter to fire.";
            }
          }
          status += "\n\nThere are ${data["ships_left"]} ships left to sink.";
        } else {
          status = "It's $opponentName's turn!\n\n"
              "Waiting for opponent to fire...";
        }
        break;
      case UIState.gameOver:
        status = "Game over!\n\n";
        if (data["winner"] == selfOwner) {
          status += "You won!";
        } else if (data["winner"] == null) {
          status += "It's a tie!";
        } else {
          status += "$opponentName won!";
        }
        break;
    }
  }

  void draw() {
    assert(stdout.hasTerminal, "Not a terminal");
    var currentTermSize =
        Object.hash(stdout.terminalColumns, stdout.terminalLines);
    if (currentTermSize != lastTermSize) {
      lastTermSize = currentTermSize;
      clearScreen();
    } else {
      moveCursor(0, 0);
    }
    var data = currentData;
    updateStatus();
    switch (state) {
      case UIState.title:
      case UIState.hostEntry:
      case UIState.hostWaiting:
      case UIState.guestEntry:
      case UIState.guestWaiting:
        stdout.write(currentLogo +
            "\n" +
            Board.combine(
              Board.host,
              Board.host,
              status: status,
              topLabel: "",
              bottomLabel: "",
            ));
        break;
      case UIState.prepare:
        selfBoard ??= Board(selfOwner ?? Player.host);
        var ready = data["self_ready"] == true;
        var large = selfBoard!;
        var small = Board.guest;
        if (ready) {
          large = small;
          small = selfBoard!;
        }
        stdout.write(currentLogo +
            "\n" +
            Board.combine(
              large,
              small,
              status: status,
              topLabel: ready ? "Waiting for opponent..." : "Place your ships!",
              bottomLabel: ready ? "Your ships" : "",
              selectedShip: ready ? null : currentShip,
            ));
        break;
      case UIState.playing:
        assert(selfBoard != null);
        assert(opponentBoard != null);
        var self = selfBoard!;
        var opponent = opponentBoard!;
        stdout.write(currentLogo +
            "\n" +
            Board.combine(
              opponent,
              self,
              status: status,
              largeIsOpponent: true,
              selected: turn == selfOwner ? currentPoint : null,
              topLabel: "$opponentName's board",
              grayOutSelected: data["guess_sent"] == true,
            ));
        break;
      case UIState.gameOver:
        assert(selfBoard != null);
        assert(opponentBoard != null);
        var self = selfBoard!;
        var opponent = opponentBoard!;
        stdout.write(currentLogo +
            "\n" +
            Board.combine(
              opponent,
              self,
              status: status,
              largeIsOpponent: true,
              topLabel: "$opponentName's board",
            ));
        break;
    }
  }
}
