import 'dart:io';

import 'client.dart';
import 'server.dart';
import 'util.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print("Battleship v1.0.0");
    print("Usage: ${Platform.executable} <mode> [<target>]");
    print("  mode: server");
    print("    target: hostname:port (default: localhost:8080)");
    print("  mode: client");
    print("    target: server_hostname:port (default: localhost:8080)");
    print("  mode: debug");
    print("");
    exit(1);
  }
  try {
    switch (arguments[0]) {
      case "server":
        if (arguments.length > 1) {
          var target = arguments[1];
          var parts = target.split(":");
          if (parts.length != 2) {
            print("Invalid target: $target");
            exit(1);
          }
          var host = parts[0];
          var port = int.parse(parts[1]);
          await serve(host, port);
        } else {
          await serve(InternetAddress.anyIPv4, 8080);
        }
        break;
      case "client":
        if (arguments.length > 1) {
          var target = arguments[1];
          var parts = target.split(":");
          if (parts.length != 2) {
            print("Invalid target: $target");
            exit(1);
          }
          var host = parts[0];
          var port = int.parse(parts[1]);
          await client(host, port);
        } else {
          await client("localhost", 8080);
        }
        break;
      default:
        print("Unknown mode: ${arguments[0]}");
        exit(1);
    }
  } catch (err) {
    // ignore
    showCursor();
  }

  showCursor();
}
