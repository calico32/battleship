import 'dart:convert';
import 'dart:io';

import 'board.dart';
import 'cell.dart';
import 'constants.dart';
import 'util.dart';

class Client {
  String id;
  late String name;
  GameState state = GameState.waiting;
  Board board;
  Player owner;
  WebSocket socket;

  Client(this.socket, this.owner, [String? name])
      : id = socket.hashCode.toString(),
        board = Board(owner) {
    this.name = name == null || name.trim() == "" ? "Player $id" : name;
  }

  @override
  int get hashCode => socket.hashCode;

  @override
  bool operator ==(other) {
    return other is Client && socket.hashCode == other.socket.hashCode;
  }
}

enum GameState {
  waiting,
  prepare,
  playing,
  finished,
  none,
}

class GameManager {
  static GameManager? _instance;

  static GameManager get instance => _instance ??= GameManager();

  Map<String, Game> games = {};

  GameManager();

  Game? operator [](String id) => games[id];

  Game create() {
    String id;
    do {
      id = generateId();
    } while (games.containsKey(id));
    var game = Game(id);
    games[id] = game;
    return game;
  }

  Game? remove(String id) {
    return games.remove(id);
  }

  GameState state(String id) {
    var game = games[id];
    if (game == null) return GameState.none;
    return game.state;
  }
}

class Game {
  String id;
  GameState state = GameState.waiting;
  Client? host;
  Client? guest;
  Player turn = Player.host;

  Game(this.id);

  // ignore: unnecessary_null_comparison
  bool get isFull => host != null && guest != null;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(other) {
    return other is Game && other.id == id;
  }

  Future<void> prepare() async {
    assert(this.host != null, "host not initialized");
    assert(this.guest != null, "guest not initialized");
    var host = this.host!;
    var guest = this.guest!;

    state = GameState.prepare;

    host.state = GameState.prepare;
    print("${msg}ws -> prepare");
    var ships = [5, 4, 3, 3, 2, 2];
    host.socket.add(json.encode({
      "type": ServerMessageType.prepare.index,
      "self": host.name,
      "opponent": guest.name,
      "board": host.board.pack(),
      "shipLengths": ships,
    }));

    guest.state = GameState.prepare;
    print("${msg}ws -> prepare");
    guest.socket.add(json.encode({
      "type": ServerMessageType.prepare.index,
      "self": guest.name,
      "opponent": host.name,
      "board": guest.board.pack(),
      "shipLengths": ships,
    }));
  }

  Future<void> play() async {
    assert(this.host != null, "host not initialized");
    assert(this.guest != null, "guest not initialized");
    var host = this.host!;
    var guest = this.guest!;

    state = GameState.playing;

    host.state = GameState.playing;
    print("${msg}ws -> play");
    host.socket.add(json.encode({
      "type": ServerMessageType.play.index,
      "turn": turn.index,
      "self_board": host.board.pack(),
      "opponent_board": guest.board.pack(showShips: false),
      "ships_left": guest.board.shipsRemaining,
    }));

    guest.state = GameState.playing;
    print("${msg}ws -> play");
    guest.socket.add(json.encode({
      "type": ServerMessageType.play.index,
      "turn": turn.index,
      "self_board": guest.board.pack(),
      "opponent_board": host.board.pack(showShips: false),
      "ships_left": host.board.shipsRemaining,
    }));
  }

  Client? addPlayer(WebSocket socket, [String? name]) {
    if (host == null) return host = Client(socket, Player.host, name);
    if (guest == null) return guest = Client(socket, Player.guest, name);
    return null;
  }

  Future<void> onGuess(Client client, Client other, int row, int col) async {
    var cell = other.board.cells.yx(row, col);
    if (cell.state == CellState.hit || cell.state == CellState.miss) {
      throw StateError("Cell is already hit or missed");
    }

    var result = {
      "type": ServerMessageType.guessResult.index,
      "turn": turn.index,
      "row": row,
      "col": col,
      "self_board": client.board.pack(),
      "opponent_board": other.board.pack(showShips: false),
      "ships_left": other.board.shipsRemaining,
    };

    Player? winner;

    if (cell.state == CellState.none) {
      cell.state = CellState.miss;
      result["result"] = "miss";
    } else {
      cell.state = CellState.hit;
      result["result"] = "hit";

      if (other.board.isAllSunk) {
        winner = client.owner;
      }
    }

    await Future.delayed(Duration(milliseconds: 500));

    print("${msg}ws -> guessResult");
    client.socket.add(json.encode(result));

    result["self_board"] = other.board.pack();
    result["opponent_board"] = client.board.pack(showShips: false);
    result["ships_left"] = client.board.shipsRemaining;

    print("${msg}ws -> guessResult");
    other.socket.add(json.encode(result));

    if (winner != null) {
      await Future.delayed(Duration(seconds: 1));
      state = GameState.finished;
      print("${msg}ws -> gameFinished");
      client.socket.add(json.encode({
        "type": ServerMessageType.gameFinished.index,
        "winner": winner.index,
      }));

      print("${msg}ws -> gameFinished");
      other.socket.add(json.encode({
        "type": ServerMessageType.gameFinished.index,
        "winner": winner.index,
      }));

      await Future.delayed(Duration(seconds: 10));
      client.socket.close(WebSocketStatus.normalClosure);
      other.socket.close(WebSocketStatus.normalClosure);
      GameManager.instance.remove(id);
    } else {
      await Future.delayed(Duration(seconds: 1));
      turn = turn == Player.host ? Player.guest : Player.host;

      print("${msg}ws -> turn");
      client.socket.add(json.encode({
        "type": ServerMessageType.turn.index,
        "turn": turn.index,
        "self_board": client.board.pack(),
        "opponent_board": other.board.pack(showShips: false),
      }));

      print("${msg}ws -> turn");
      other.socket.add(json.encode({
        "type": ServerMessageType.turn.index,
        "turn": turn.index,
        "self_board": other.board.pack(),
        "opponent_board": client.board.pack(showShips: false),
      }));
    }
  }

  Future<void> onMessage(Client client, Map<String, dynamic> message) async {
    ClientMessageType type;
    try {
      type = ClientMessageType.values[message["type"]];
    } catch (err) {
      throw ArgumentError("Invalid message type ${message["type"]}");
    }

    print("${msg}ws <- ${type.name}");

    switch (type) {
      case ClientMessageType.ready:
        assert(this.host != null, "host not initialized");
        assert(this.guest != null, "guest not initialized");
        var host = this.host!;
        var guest = this.guest!;

        client.board = Board.unpack(message["board"]);
        client.state = GameState.playing;

        var other = client == host ? guest : host;

        print("${msg}ws -> ready");
        other.socket.add(json.encode({
          "type": ServerMessageType.opponentReady.index,
        }));

        if (host.state == GameState.playing &&
            guest.state == GameState.playing) {
          play();
        }
        break;
      case ClientMessageType.guess:
        var other = client == host ? guest : host;
        assert(other != null);
        var row = message["row"];
        var col = message["col"];
        onGuess(client, other!, row, col);
        break;
    }
  }
}
