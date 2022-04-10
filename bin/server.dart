import 'dart:convert';
import 'dart:io';

import 'constants.dart';
import 'game.dart';
import 'util.dart';

Future<void> serve([dynamic host, int port = 8080]) async {
  var manager = GameManager.instance;
  var server =
      await HttpServer.bind(host ?? InternetAddress.loopbackIPv4, port);

  clearScreen();
  print("Battleship Server v1");
  print("Listening on ${server.address.address}:${server.port}");

  await server.forEach((req) async {
    var path = req.uri.pathSegments;
    var res = req.response;

    print("<- ${req.method} ${req.uri.toString()}");

    if (path.isEmpty || path.length > 1) {
      res
        ..statusCode = HttpStatus.notFound
        ..close();
      return;
    }

    if (path[0] == "create") {
      var game = manager.create();
      var response = json.encode({"id": game.id});
      print('  -> ${HttpStatus.ok} $response');
      res
        ..statusCode = HttpStatus.ok
        ..write(response)
        ..close();
      return;
    }

    if (path[0] == "status") {
      var id = req.uri.queryParameters["id"];
      if (id == null) {
        print("  -> ${HttpStatus.badRequest}");
        res
          ..statusCode = HttpStatus.badRequest
          ..close();
        return;
      }

      var response = json.encode({"id": id, "state": manager.state(id).index});
      print('  -> ${HttpStatus.ok} $response');
      res
        ..statusCode = HttpStatus.ok
        ..write(response)
        ..close();
      return;
    }

    if (path[0] == "ws") {
      var id = req.uri.queryParameters["id"];
      var name = req.uri.queryParameters["name"];

      if (id == null || id == "") {
        print("  -> ${HttpStatus.badRequest}");
        res
          ..statusCode = HttpStatus.badRequest
          ..close();
        return;
      }

      var game = manager[id];
      if (game == null) {
        print("  -> ${HttpStatus.notFound}");
        res
          ..statusCode = HttpStatus.notFound
          ..close();
        return;
      }

      if (game.isFull) {
        print("  -> ${HttpStatus.badRequest}");
        res
          ..statusCode = HttpStatus.badRequest
          ..close();
        return;
      }

      WebSocket socket;
      try {
        socket = await WebSocketTransformer.upgrade(req);
      } catch (err) {
        print("  -> ${HttpStatus.internalServerError}");
        return;
      }

      var client = game.addPlayer(socket, name);
      if (client == null) {
        print("  -> ${HttpStatus.badRequest}");
        res
          ..statusCode = HttpStatus.badRequest
          ..close();
        return;
      }

      print("  -> ${HttpStatus.switchingProtocols}");
      print("${msg}ws -> init");
      socket.add(json.encode({
        "type": ServerMessageType.init.index,
        "id": client.id,
        "name": client.name,
        "player": client.owner.index,
      }));

      if (game.isFull) {
        game.prepare();
      }

      await socket.forEach((message) {
        if (message is String) {
          game.onMessage(client, json.decode(message));
        } else {
          print("Unknown message: $message");
        }
      });

      print("${msg}ws <- close");

      return;
    }

    print("  -> ${HttpStatus.notFound}");
    res
      ..statusCode = HttpStatus.notFound
      ..close();
  });
}
