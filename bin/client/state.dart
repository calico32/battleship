import 'dart:convert';
import 'dart:io';

// official dart http library, by the Dart project authors
// https://pub.dev/packages/http
// https://github.com/dart-lang/http
import "package:http/http.dart" as http;

import '../board.dart';
import '../cell.dart';
import '../constants.dart';
import '../game.dart';
import '../ship.dart';

final defaultState = <UIState, Map<String, dynamic> Function()>{
  UIState.title: () => {"selected": 0},
  UIState.hostEntry: () => {"selected": 0, "name": "", "status": ""},
  UIState.hostWaiting: () => {},
  UIState.guestEntry: () => {"selected": 0, "name": "", "id": "", "status": ""},
  UIState.guestWaiting: () => {},
  UIState.prepare: () => {"self_ready": false, "opponent_ready": false},
  UIState.playing: () => {
        "guess_result": "",
        "guess_turn": null,
        "guess_col": 0,
        "guess_row": 0,
        "guess_sent": false,
        "ships_left": 0,
      },
  UIState.gameOver: () => {"winner": null},
};

mixin ClientState {
  UIState state = UIState.title;
  Map<UIState, Map<String, dynamic>> stateData = {};

  String? selfName;
  Player? selfOwner;
  Board? selfBoard;
  String? opponentName;
  Player? opponentOwner;
  Board? opponentBoard;
  String? gameId;
  Player turn = Player.host;

  late dynamic host;
  late int port;
  late String server;
  WebSocket? socket;

  List<int> shipsToPlace = [5, 4, 3, 2, 2];
  Ship? currentShip;
  Point currentPoint = Point.zero;

  Map<String, dynamic> getData(UIState state) =>
      stateData.putIfAbsent(state, () => defaultState[state]!());
  Map<String, dynamic> get currentData => getData(state);

  Future<GameState> getGameState(String id) async {
    var proto = port == 443 ? "https" : "http";
    var uri = Uri(
      scheme: proto,
      host: host,
      port: port,
      path: "/status",
      queryParameters: {
        "id": id,
      },
    );
    var res = await http.get(uri);
    var json = jsonDecode(res.body);
    return GameState.values[json["state"]];
  }

  Future<String> createRoom() async {
    var proto = port == 443 ? "https" : "http";
    var uri = Uri(
      scheme: proto,
      host: host,
      port: port,
      path: "/create",
    );
    var res = await http.get(uri);
    var json = jsonDecode(res.body);
    return json["id"];
  }

  Future<WebSocket> joinRoom() async {
    gameId ??= await createRoom();

    var proto = port == 443 ? "wss" : "ws";
    var uri = Uri(
      scheme: proto,
      host: host,
      port: port,
      path: "ws",
      queryParameters: {
        "id": gameId,
        "name": selfName,
      },
    );

    return await WebSocket.connect(uri.toString());
  }

  Future<void> onClose(_) async {
    if (socket != null) {
      await socket!.close();
      socket = null;
    }

    gameId = null;
    selfName = null;
    selfOwner = null;
    selfBoard = null;
    opponentName = null;
    opponentOwner = null;
    opponentBoard = null;
    turn = Player.host;
    currentShip = null;
    currentPoint = Point.zero;
    stateData = {};
    state = UIState.title;
  }

  Future<void> listen() async {
    if (socket == null) {
      throw StateError("socket not initialized");
    }

    await socket!.forEach((message) async {
      if (message is String) {
        return await _onMessage(jsonDecode(message));
      }

      throw ArgumentError("Unhandled message type ${message.runtimeType}");
    });

    onClose(null);
  }

  Future<void> update() async {}

  Future<void> _onMessage(Map<String, dynamic> message) async {
    ServerMessageType type;
    try {
      type = ServerMessageType.values[message["type"]];
    } catch (err) {
      throw ArgumentError("Invalid message type ${message["type"]}");
    }

    switch (type) {
      case ServerMessageType.init:
        selfName = message["name"];
        selfOwner = Player.values[message["player"]];
        break;
      case ServerMessageType.prepare:
        state = UIState.prepare;
        selfName = message["self"];
        opponentName = message["opponent"];
        selfBoard = Board.unpack(message["board"]);
        shipsToPlace = List<int>.from(message["shipLengths"]);

        currentShip = Ship(Point.zero, shipsToPlace[0], Orientation.horizontal);
        selfBoard!.addShip(currentShip!);
        break;
      case ServerMessageType.opponentReady:
        getData(UIState.prepare)["opponent_ready"] = true;
        break;
      case ServerMessageType.play:
        state = UIState.playing;
        turn = Player.values[message["turn"]];
        selfBoard = Board.unpack(message["self_board"]);
        opponentBoard = Board.unpack(message["opponent_board"]);
        currentData["ships_left"] = message["ships_left"];
        break;
      case ServerMessageType.guessResult:
        state = UIState.playing;
        selfBoard = Board.unpack(message["self_board"]);
        opponentBoard = Board.unpack(message["opponent_board"]);
        var data = currentData;
        data["guess_result"] = message["result"];
        data["guess_turn"] = Player.values[message["turn"]];
        data["guess_col"] = message["col"];
        data["guess_row"] = message["row"];
        data["ships_left"] = message["ships_left"];
        var targetCells = data["guess_turn"] == selfOwner
            ? opponentBoard!.cells
            : selfBoard!.cells;
        var cell = targetCells.xy(message["col"], message["row"]);
        cell.state =
            data["guess_result"] == "hit" ? CellState.hit : CellState.miss;
        break;
      case ServerMessageType.turn:
        state = UIState.playing;
        turn = Player.values[message["turn"]];
        selfBoard = Board.unpack(message["self_board"]);
        opponentBoard = Board.unpack(message["opponent_board"]);
        var data = currentData;
        data["guess_result"] = "";
        data["guess_turn"] = null;
        data["guess_col"] = 0;
        data["guess_row"] = 0;
        data["guess_sent"] = false;
        break;
      case ServerMessageType.gameFinished:
        state = UIState.gameOver;
        currentData["winner"] = Player.values[message["winner"]];
        break;
    }
    update();
  }
}
