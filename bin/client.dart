import 'dart:io';

import 'client/draw.dart';
import 'client/input.dart';
import 'client/state.dart';
import 'util.dart';

Future<void> client([dynamic host, int port = 8080]) async {
  hideCursor();
  stdin.echoMode = false;
  stdin.lineMode = false;

  var client = Client(host, port);
  await client.run();
  showCursor();
}

class Client with ClientState, ClientUI, ClientInputHandler {
  Client([host, port = 8080]) {
    host ??= InternetAddress.loopbackIPv4;

    this.host = host;
    this.port = port;
    if (host is String) {
      server = "$host:$port";
    } else if (host is InternetAddress) {
      server = "${host.address}:$port";
    } else {
      throw ArgumentError("unknown type for host ${host.runtimeType}");
    }
  }

  Future<void> run() async {
    clearScreen();

    animateLogo();
    await stdin.forEach((key) async {
      if (key.isEmpty || key[0] == -1) throw Future.error("exit");

      var interrupted = ["\x03", "\x04"].map(ord);
      if (key[0] == -1 || interrupted.contains(key[0])) {
        return Future.error("exit");
      }

      String keyString = String.fromCharCodes(key);

      await handleInput(keyString).then((shouldExit) {
        if (shouldExit) {
          return Future.error("exit");
        } else {
          moveCursor(0, 0);
          draw();
        }
      }).catchError((e) {
        if (e is String && e == "exit") {
        } else {
          print("\nError: $e");
        }
        shouldAnimate = false;
        showCursor();
        exit(0);
      });
    }).catchError((e) {
      if (e is String && e == "exit") {
      } else {
        print("\nError: $e");
      }
      shouldAnimate = false;
      showCursor();
      exit(0);
    });
  }
}
